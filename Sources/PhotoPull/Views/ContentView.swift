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
        _ = browser.deviceAccessVersion
        guard settings.isReadyToImport, selectedDevice != nil else { return false }
        return !importer.isRunning
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
            .id(browser.deviceAccessVersion)

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
        // onReceive вместо onChange(of:perform:) — последняя депрекейтнута в новых SDK,
        // а onReceive поддерживается на macOS 13+ без предупреждений.
        .onReceive(browser.$devices) { devices in
            let ids = devices.map(\.id)
            // Автовыбор единственного устройства и сброс исчезнувшего выбора.
            if selectedDeviceID == nil, ids.count == 1 {
                selectedDeviceID = ids.first
            } else if let selectedDeviceID, !ids.contains(selectedDeviceID) {
                self.selectedDeviceID = ids.first
            }
        }
        .onReceive(importer.$state) { state in
            switch state {
            case .idle, .finished, .failed:
                browser.reattachDelegates()
            case .openingSession, .downloading:
                break
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
        importer.startImport(
            device: device,
            destination: destination,
            mode: settings.transferMode,
            filterDaysBack: settings.filterDaysBack
        )
    }
}
