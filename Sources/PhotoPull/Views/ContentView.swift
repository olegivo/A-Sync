import SwiftUI
import Shared

struct ContentView: View {

    @EnvironmentObject private var settings: AppSettings
    @StateObject private var browser = CameraBrowser()
    @StateObject private var importer = Importer()

    @State private var selectedDeviceID: String?

    private var selectedDevice: DiscoveredDevice? {
        browser.devices.first { $0.id == selectedDeviceID }
    }

    private var canStartImport: Bool {
        guard settings.isReadyToImport, let device = selectedDevice else { return false }
        return !device.isRestricted && !importer.isRunning
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            SettingsSection()

            Divider()

            DeviceSection(
                devices: browser.devices,
                isBrowsing: browser.isBrowsing,
                selectedDeviceID: $selectedDeviceID
            )

            Divider()

            ImportSection(
                importer: importer,
                canStart: canStartImport,
                onStart: startImport
            )

            Spacer()
        }
        .padding(24)
        .onAppear { browser.start() }
        .onDisappear { browser.stop() }
        .onChange(of: browser.devices.map(\.id)) { ids in
            // Автовыбор единственного устройства и сброс исчезнувшего выбора.
            if selectedDeviceID == nil, ids.count == 1 {
                selectedDeviceID = ids.first
            } else if let selectedDeviceID, !ids.contains(selectedDeviceID) {
                self.selectedDeviceID = ids.first
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PhotoPull")
                .font(.largeTitle.bold())
            Text("Импорт фото и видео с iPhone на этот Mac")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func startImport() {
        guard let device = selectedDevice?.device,
              let destination = settings.destinationURL else { return }
        importer.startImport(device: device, destination: destination, mode: settings.transferMode)
    }
}
