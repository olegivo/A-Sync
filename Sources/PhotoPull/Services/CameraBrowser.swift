import Combine
import Foundation
import ImageCaptureCore

/// Обнаружение камер (в т.ч. iPhone) через `ICDeviceBrowser`.
///
/// Ищем устройства типа «камера», подключённые локально (USB) и по сети (Bonjour).
///
/// ВАЖНО про Wi-Fi: iPhone, как правило, НЕ публикует свою фотоплёнку для Image Capture
/// по Wi-Fi (в отличие от части сетевых камер с PTP/IP). Поэтому в реальности по этому
/// каналу стабильно работает именно USB. Сетевой режим оставлен включённым на случай
/// совместимых устройств, но полагаться на Wi-Fi-обнаружение iPhone без компаньон-приложения
/// на телефоне нельзя. Подробности — в README, раздел «Ограничение Wi-Fi».
///
/// Для Apple-устройств сразу открываем сессию и подписываемся на смену ограничения доступа —
/// иначе `isAccessRestrictedAppleDevice` может оставаться true, хотя «Захват изображений»
/// уже видит файлы (типично на iOS 15).
final class CameraBrowser: NSObject, ObservableObject, ICDeviceBrowserDelegate, ICCameraDeviceDelegate {

    @Published private(set) var devices: [DiscoveredDevice] = []
    @Published private(set) var isBrowsing = false
    /// Триггер перерисовки UI при смене `isAccessRestrictedAppleDevice`.
    @Published private(set) var deviceAccessVersion = 0

    private let browser = ICDeviceBrowser()
    private var accessRefreshCancellable: AnyCancellable?

    override init() {
        super.init()
        browser.delegate = self

        let mask =
            ICDeviceTypeMask.camera.rawValue |
            ICDeviceLocationTypeMask.local.rawValue |
            ICDeviceLocationTypeMask.bonjour.rawValue
        browser.browsedDeviceTypeMask = ICDeviceTypeMask(rawValue: mask) ?? .camera
    }

    func start() {
        guard !isBrowsing else { return }
        isBrowsing = true
        browser.start()
        startAccessRefreshTimer()
    }

    func stop() {
        guard isBrowsing else { return }
        isBrowsing = false
        browser.stop()
        accessRefreshCancellable?.cancel()
        accessRefreshCancellable = nil
        for discovered in devices {
            discovered.device.requestCloseSession()
            if discovered.device.delegate === self {
                discovered.device.delegate = nil
            }
        }
    }

    /// Восстанавливает делегат и сессию после импорта (`Importer` временно забирает делегат).
    func reattachDelegates() {
        for discovered in devices {
            let camera = discovered.device
            if camera.delegate == nil {
                camera.delegate = self
            }
            if camera.mediaFiles == nil {
                camera.requestOpenSession()
            }
        }
        bumpAccessVersion()
    }

    private func startAccessRefreshTimer() {
        accessRefreshCancellable = Timer.publish(every: 1.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isBrowsing, !self.devices.isEmpty else { return }
                self.bumpAccessVersion()
            }
    }

    private func bumpAccessVersion() {
        deviceAccessVersion += 1
    }

    private func attach(_ camera: ICCameraDevice) {
        camera.delegate = self
        let discovered = DiscoveredDevice(device: camera)
        if !devices.contains(discovered) {
            devices.append(discovered)
        }
        // Как «Захват изображений»: открываем сессию при появлении устройства.
        camera.requestOpenSession()
        bumpAccessVersion()
    }

    // MARK: - ICDeviceBrowserDelegate

    func deviceBrowser(_ browser: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool) {
        guard let camera = device as? ICCameraDevice else { return }
        DispatchQueue.main.async { [weak self] in
            self?.attach(camera)
        }
    }

    func deviceBrowser(_ browser: ICDeviceBrowser, didRemove device: ICDevice, moreGoing: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let camera = device as? ICCameraDevice, camera.delegate === self {
                camera.delegate = nil
            }
            self.devices.removeAll { $0.device === device }
            self.bumpAccessVersion()
        }
    }

    // MARK: - ICCameraDeviceDelegate — смена ограничения доступа

    nonisolated func cameraDeviceDidRemoveAccessRestriction(_ device: ICDevice) {
        DispatchQueue.main.async { [weak self] in
            self?.bumpAccessVersion()
        }
    }

    nonisolated func cameraDeviceDidEnableAccessRestriction(_ device: ICDevice) {
        DispatchQueue.main.async { [weak self] in
            self?.bumpAccessVersion()
        }
    }

    nonisolated func deviceDidBecomeReady(withCompleteContentCatalog device: ICCameraDevice) {
        DispatchQueue.main.async { [weak self] in
            self?.bumpAccessVersion()
        }
    }

    nonisolated func device(_ device: ICDevice, didOpenSessionWithError error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.bumpAccessVersion()
        }
    }

    nonisolated func device(_ device: ICDevice, didCloseSessionWithError error: Error?) {}

    nonisolated func didRemove(_ device: ICDevice) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.devices.removeAll { $0.device === device }
            self.bumpAccessVersion()
        }
    }

    nonisolated func cameraDevice(_ camera: ICCameraDevice, didAdd items: [ICCameraItem]) {}
    nonisolated func cameraDevice(_ camera: ICCameraDevice, didRemove items: [ICCameraItem]) {}
    nonisolated func cameraDevice(_ camera: ICCameraDevice, didRenameItems items: [ICCameraItem]) {}
    nonisolated func cameraDevice(_ camera: ICCameraDevice, didReceiveThumbnail thumbnail: CGImage?, for item: ICCameraItem, error: Error?) {}
    nonisolated func cameraDevice(_ camera: ICCameraDevice, didReceiveMetadata metadata: [AnyHashable: Any]?, for item: ICCameraItem, error: Error?) {}
    nonisolated func cameraDeviceDidChangeCapability(_ camera: ICCameraDevice) {}
    nonisolated func cameraDevice(_ camera: ICCameraDevice, didReceivePTPEvent eventData: Data) {}
    nonisolated func cameraDevice(_ camera: ICCameraDevice, didCompleteDeleteFilesWithError error: Error?) {}
    nonisolated func cameraDevice(_ cameraDevice: ICCameraDevice, shouldGetThumbnailOf item: ICCameraItem) -> Bool { false }
    nonisolated func cameraDevice(_ cameraDevice: ICCameraDevice, shouldGetMetadataOf item: ICCameraItem) -> Bool { false }
}
