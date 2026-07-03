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

    /// Транспорт подключения — для подсказки пользователю (кабель/накопитель).
    ///
    /// `transportType` в текущем SDK — строковое значение (`ICDeviceTransport`), поэтому
    /// сравниваем по строковому представлению: это устойчиво к тому, импортируется ли тип
    /// как `String` или как типизированная строковая обёртка, и не зависит от набора
    /// констант (напр., `ICTransportTypeTCPIP` в текущем SDK отсутствует).
    var transportDescription: String {
        let transport = device.transportType.map { "\($0)" } ?? ""
        if transport.contains("USB") { return "USB (кабель)" }
        if transport.contains("MassStorage") { return "Накопитель" }
        if transport.contains("Bluetooth") { return "Bluetooth" }
        return "Подключено"
    }

    /// Заблокированное/недоверенное Apple-устройство: импорт невозможен без разблокировки.
    var isRestricted: Bool {
        device.isAccessRestrictedAppleDevice
    }

    static func == (lhs: DiscoveredDevice, rhs: DiscoveredDevice) -> Bool {
        lhs.id == rhs.id
    }
}
