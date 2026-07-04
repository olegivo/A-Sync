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
final class CameraBrowser: NSObject, ObservableObject, ICDeviceBrowserDelegate {

    @Published private(set) var devices: [DiscoveredDevice] = []
    @Published private(set) var isBrowsing = false

    private let browser = ICDeviceBrowser()

    override init() {
        super.init()
        browser.delegate = self

        // Комбинируем маску типа устройства (камера) с масками расположения (локально + сеть).
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
    }

    func stop() {
        guard isBrowsing else { return }
        isBrowsing = false
        browser.stop()
    }

    // MARK: - ICDeviceBrowserDelegate

    func deviceBrowser(_ browser: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool) {
        guard let camera = device as? ICCameraDevice else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let discovered = DiscoveredDevice(device: camera)
            if !self.devices.contains(discovered) {
                self.devices.append(discovered)
            }
        }
    }

    func deviceBrowser(_ browser: ICDeviceBrowser, didRemove device: ICDevice, moreGoing: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.devices.removeAll { $0.device === device }
        }
    }
}
