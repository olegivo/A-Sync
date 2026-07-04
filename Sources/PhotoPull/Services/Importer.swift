import Foundation
import ImageCaptureCore
import Shared

/// Контроллер импорта медиафайлов с камеры/iPhone через ImageCaptureCore.
///
/// Последовательность:
///   1. `requestOpenSession()` на устройстве;
///   2. ждём `deviceDidBecomeReady(withCompleteContentCatalog:)` — каталог контента готов;
///   3. скачиваем файлы по одному (`requestDownloadFile`) в папку назначения;
///   4. для режима `.move` включаем опцию удаления оригинала после успешной загрузки;
///   5. по завершении закрываем сессию и публикуем сводку.
///
/// Загрузка идёт последовательно — так проще и понятнее прогресс, и не перегружается канал.
@MainActor
final class Importer: NSObject, ObservableObject {

    enum State: Equatable {
        case idle
        case openingSession
        case downloading(completed: Int, total: Int)
        case finished(summary: String)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    /// Прогресс текущего файла в диапазоне 0...1.
    @Published private(set) var currentFileProgress: Double = 0
    /// Имя файла, который скачивается прямо сейчас.
    @Published private(set) var currentFileName: String = ""

    private var device: ICCameraDevice?
    private var destinationURL: URL?
    private var isAccessingResource = false
    private var transferMode: TransferMode = TransferMode.copyMode
    private var filterDaysBack: Int = 0

    private var queue: [ICCameraFile] = []
    private var totalCount = 0
    private var succeeded = 0
    private var failed = 0
    private var usedFilenames: Set<String> = []
    private var hasStartedDownloads = false
    /// Флаг отмены: гасит асинхронные колбэки, которые могут прийти после `cancel()`.
    private var isCancelled = false
    /// Watchdog: срабатывает, если после открытия сессии каталог так и не стал готов.
    private var readinessTimeout: DispatchWorkItem?

    /// Максимум ожидания готовности каталога контента после открытия сессии.
    private let readinessTimeoutSeconds: TimeInterval = 120

    var isRunning: Bool {
        switch state {
        case .idle, .finished, .failed: return false
        case .openingSession, .downloading: return true
        }
    }

    private var processedCount: Int { succeeded + failed }

    // MARK: - Public API

    func startImport(device: ICCameraDevice, destination: URL, mode: TransferMode, filterDaysBack: Int) {
        guard !isRunning else { return }

        if device.isAccessRestrictedAppleDevice {
            state = .failed("iPhone заблокирован или не доверяет этому Mac. Разблокируйте телефон и нажмите «Доверять».")
            return
        }

        self.device = device
        self.destinationURL = destination
        self.transferMode = mode
        self.filterDaysBack = filterDaysBack
        self.succeeded = 0
        self.failed = 0
        self.usedFilenames = []
        self.queue = []
        self.hasStartedDownloads = false
        self.isCancelled = false
        self.currentFileProgress = 0
        self.currentFileName = ""

        isAccessingResource = destination.startAccessingSecurityScopedResource()
        usedFilenames = existingFilenames(in: destination)

        device.delegate = self
        state = .openingSession
        device.requestOpenSession()
        scheduleReadinessTimeout()
    }

    func cancel() {
        guard isRunning else { return }
        isCancelled = true
        device?.cancelDownload()
        finish(closingSession: true)
        state = .failed("Импорт отменён")
    }

    // MARK: - Private helpers

    private func scheduleReadinessTimeout() {
        readinessTimeout?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.isRunning, !self.hasStartedDownloads else { return }
            self.finish(closingSession: true)
            self.state = .failed("Устройство не ответило за отведённое время. Переподключите iPhone и повторите.")
        }
        readinessTimeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + readinessTimeoutSeconds, execute: work)
    }

    private func existingFilenames(in directory: URL) -> Set<String> {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return Set(names)
    }

    private func beginDownloadsIfNeeded() {
        guard !isCancelled else { return }
        guard !hasStartedDownloads, let device else { return }
        hasStartedDownloads = true
        readinessTimeout?.cancel()
        readinessTimeout = nil

        let now = Date()
        let media = (device.mediaFiles ?? [])
            .compactMap { $0 as? ICCameraFile }
            .filter { file in
                // Дата съёмки (EXIF) с фолбэком на файловую дату создания.
                let creationDate = file.creationDate ?? file.fileCreationDate
                return SharedLogic.shouldInclude(
                    creationDate: creationDate,
                    now: now,
                    maxAgeDays: filterDaysBack
                )
            }
        queue = media
        totalCount = media.count

        guard !queue.isEmpty else {
            finish(closingSession: true)
            state = .finished(summary: SharedLogic.summary(succeeded: 0, failed: 0))
            return
        }

        state = .downloading(completed: 0, total: totalCount)
        downloadNext()
    }

    private func downloadNext() {
        guard !isCancelled else { return }
        guard let device, let destinationURL else { return }

        guard !queue.isEmpty else {
            finish(closingSession: true)
            state = .finished(summary: SharedLogic.summary(succeeded: succeeded, failed: failed))
            return
        }

        let file = queue.removeFirst()
        let originalName = file.name ?? "file-\(processedCount + 1)"
        let uniqueName = SharedLogic.uniqueFilename(originalName, existing: usedFilenames)
        usedFilenames.insert(uniqueName)

        currentFileName = uniqueName
        currentFileProgress = 0

        var options: [ICDownloadOption: Any] = [
            .downloadsDirectoryURL: destinationURL as NSURL,
            .saveAsFilename: uniqueName,
            .overwrite: NSNumber(value: false)
        ]
        if transferMode.deletesSourceAfterDownload {
            options[.deleteAfterSuccessfulDownload] = NSNumber(value: true)
        }

        device.requestDownloadFile(
            file,
            options: options,
            downloadDelegate: self,
            didDownloadSelector: #selector(didDownloadFile(_:error:options:contextInfo:)),
            contextInfo: nil
        )
    }

    private func finish(closingSession: Bool) {
        readinessTimeout?.cancel()
        readinessTimeout = nil
        if closingSession {
            device?.requestCloseSession()
        }
        if isAccessingResource {
            destinationURL?.stopAccessingSecurityScopedResource()
            isAccessingResource = false
        }
        device?.delegate = nil
        // Обнуляем состояние, чтобы запоздалые колбэки не смогли перезапустить импорт.
        device = nil
        destinationURL = nil
        queue = []
    }
}

// MARK: - ICDeviceDelegate

extension Importer: ICCameraDeviceDelegate {

    nonisolated func device(_ device: ICDevice, didOpenSessionWithError error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let error {
                self.finish(closingSession: false)
                self.state = .failed("Не удалось открыть сессию: \(error.localizedDescription)")
            }
            // Успех: ждём deviceDidBecomeReadyWithCompleteContentCatalog.
        }
    }

    nonisolated func device(_ device: ICDevice, didCloseSessionWithError error: Error?) {}

    nonisolated func didRemove(_ device: ICDevice) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.finish(closingSession: false)
            self.state = .failed("Устройство отключено во время импорта")
        }
    }

    nonisolated func deviceDidBecomeReady(withCompleteContentCatalog device: ICCameraDevice) {
        DispatchQueue.main.async { [weak self] in
            self?.beginDownloadsIfNeeded()
        }
    }

    // MARK: ICCameraDeviceDelegate — методы протокола без действий в рамках MVP.

    nonisolated func cameraDevice(_ camera: ICCameraDevice, didAdd items: [ICCameraItem]) {}
    nonisolated func cameraDevice(_ camera: ICCameraDevice, didRemove items: [ICCameraItem]) {}
    nonisolated func cameraDevice(_ camera: ICCameraDevice, didRenameItems items: [ICCameraItem]) {}
    nonisolated func cameraDevice(_ camera: ICCameraDevice, didReceiveThumbnail thumbnail: CGImage?, for item: ICCameraItem, error: Error?) {}
    nonisolated func cameraDevice(_ camera: ICCameraDevice, didReceiveMetadata metadata: [AnyHashable: Any]?, for item: ICCameraItem, error: Error?) {}
    nonisolated func cameraDeviceDidChangeCapability(_ camera: ICCameraDevice) {}
    nonisolated func cameraDevice(_ camera: ICCameraDevice, didReceivePTPEvent eventData: Data) {}
    nonisolated func cameraDevice(_ camera: ICCameraDevice, didCompleteDeleteFilesWithError error: Error?) {}
    nonisolated func cameraDeviceDidEnableAccessRestriction(_ device: ICDevice) {}
    nonisolated func cameraDeviceDidRemoveAccessRestriction(_ device: ICDevice) {}
    nonisolated func cameraDevice(_ cameraDevice: ICCameraDevice, shouldGetThumbnailOf item: ICCameraItem) -> Bool { false }
    nonisolated func cameraDevice(_ cameraDevice: ICCameraDevice, shouldGetMetadataOf item: ICCameraItem) -> Bool { false }
}

// MARK: - ICCameraDeviceDownloadDelegate

extension Importer: ICCameraDeviceDownloadDelegate {

    @objc nonisolated func didDownloadFile(_ file: ICCameraFile, error: Error?, options: [String: Any], contextInfo: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isCancelled else { return }
            if error == nil {
                self.succeeded += 1
            } else {
                self.failed += 1
            }
            self.currentFileProgress = 0
            self.state = .downloading(completed: self.processedCount, total: self.totalCount)
            self.downloadNext()
        }
    }

    nonisolated func didReceiveDownloadProgress(for file: ICCameraFile, downloadedBytes: off_t, maxBytes: off_t) {
        guard maxBytes > 0 else { return }
        let fraction = Double(downloadedBytes) / Double(maxBytes)
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isCancelled else { return }
            self.currentFileProgress = min(max(fraction, 0), 1)
        }
    }
}
