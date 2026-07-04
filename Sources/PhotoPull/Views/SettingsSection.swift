import SwiftUI
import AppKit
import Shared

/// Раздел настроек MVP: путь назначения и режим (копировать/переместить).
struct SettingsSection: View {

    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Настройки")
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Папка приёма:")
                    .frame(width: 110, alignment: .leading)
                Text(settings.destinationDisplayPath)
                    .foregroundStyle(settings.destinationURL == nil ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Выбрать…", action: chooseDestination)
            }

            HStack(spacing: 12) {
                Text("Режим:")
                    .frame(width: 110, alignment: .leading)
                Picker("", selection: $settings.transferMode) {
                    ForEach(TransferMode.uiCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 260, alignment: .leading)
                Spacer()
            }

            if settings.transferMode.deletesSourceAfterDownload {
                Label("Файлы будут удалены с iPhone после успешной загрузки.",
                      systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            dateFilterRow
        }
    }

    private var dateFilterRow: some View {
        HStack(spacing: 12) {
            Text("Только новые:")
                .frame(width: 110, alignment: .leading)

            Toggle("", isOn: Binding(
                get: { settings.isDateFilterEnabled },
                set: { settings.isDateFilterEnabled = $0 }
            ))
            .labelsHidden()
            .toggleStyle(.switch)

            if settings.isDateFilterEnabled {
                Stepper(
                    value: $settings.filterDaysBack,
                    in: 1...3650
                ) {
                    Text("за последние \(settings.filterDaysBack) дн.")
                }
                .fixedSize()
            } else {
                Text("копировать все файлы")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func chooseDestination() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Выбрать"
        panel.message = "Выберите папку, в которую будут сохраняться фото и видео"
        if panel.runModal() == .OK, let url = panel.url {
            settings.setDestination(url)
        }
    }
}
