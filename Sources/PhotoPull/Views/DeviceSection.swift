import SwiftUI

/// Список обнаруженных устройств (iPhone по кабелю/сети).
struct DeviceSection: View {

    let devices: [DiscoveredDevice]
    let isBrowsing: Bool
    @Binding var selectedDeviceID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Устройства")
                    .font(.headline)
                Spacer()
                if isBrowsing {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if devices.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("iPhone не найден")
                        .foregroundStyle(.secondary)
                    Text("Подключите iPhone кабелем и разблокируйте его. При первом подключении подтвердите «Доверять этому компьютеру».")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else {
                List(devices, selection: $selectedDeviceID) { device in
                    HStack(spacing: 10) {
                        Image(systemName: "iphone")
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name)
                            Text(device.transportDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if device.isRestricted {
                            Label("Заблокирован", systemImage: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .labelStyle(.titleAndIcon)
                        }
                    }
                    .tag(device.id)
                }
                .frame(minHeight: 100, maxHeight: 160)
            }
        }
    }
}
