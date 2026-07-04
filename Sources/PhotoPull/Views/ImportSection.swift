import SwiftUI

/// Ручной запуск импорта, индикатор прогресса и итоговая сводка.
struct ImportSection: View {

    @ObservedObject var importer: Importer
    let canStart: Bool
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onStart) {
                    Label("Импортировать", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canStart)

                if importer.isRunning {
                    Button("Отмена", role: .cancel) {
                        importer.cancel()
                    }
                }
                Spacer()
            }

            statusView
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch importer.state {
        case .idle:
            EmptyView()

        case .openingSession:
            Label("Открываю сессию с устройством…", systemImage: "hourglass")
                .font(.callout)
                .foregroundStyle(.secondary)

        case let .downloading(completed, total):
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: Double(completed), total: Double(max(total, 1))) {
                    Text("Загрузка \(completed) из \(total)")
                        .font(.callout)
                }
                if !importer.currentFileName.isEmpty {
                    ProgressView(value: importer.currentFileProgress) {
                        Text(importer.currentFileName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }

        case let .finished(summary):
            Label(summary, systemImage: "checkmark.circle.fill")
                .font(.callout)
                .foregroundStyle(.green)

        case let .failed(message):
            Label(message, systemImage: "xmark.octagon.fill")
                .font(.callout)
                .foregroundStyle(.red)
        }
    }
}
