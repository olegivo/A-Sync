import Foundation
import ImageCaptureCore

/// Идентифицируемая обёртка над `ICCameraDevice` для отображения в SwiftUI-списке.
struct DiscoveredDevice: Identifiable, Equatable {

    let device: ICCameraDevice

    /// Стабильный идентификатор устройства.
    var id: String {
        device.uuidString ?? device.persistentIDString ?? device.name ?? "\(ObjectIdentifier(device).hashValue)"
    }

    var name: String {
        device.name ?? "Неизвестное устройство"
    }

    /// Транспорт подключения — для подсказки пользователю (кабель/сеть).
    var transportDescription: String {
        switch device.transportType {
        case ICTransportTypeUSB:
            return "USB (кабель)"
        case ICTransportTypeTCPIP:
            return "Wi-Fi / сеть"
        case ICTransportTypeMassStorage:
            return "Накопитель"
        case ICTransportTypeBluetooth:
            return "Bluetooth"
        default:
            return "Подключено"
        }
    }

    /// Заблокированное/недоверенное Apple-устройство: импорт невозможен без разблокировки.
    var isRestricted: Bool {
        device.isAccessRestrictedAppleDevice
    }

    static func == (lhs: DiscoveredDevice, rhs: DiscoveredDevice) -> Bool {
        lhs.id == rhs.id
    }
}
