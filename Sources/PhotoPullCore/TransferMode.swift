import Foundation

/// Режим переноса медиафайлов с устройства.
public enum TransferMode: String, Codable, CaseIterable, Sendable {
    /// Копировать: файлы остаются на устройстве.
    case copy
    /// Переместить: после успешной загрузки файл удаляется с устройства.
    case move

    /// Человекочитаемое название для UI.
    public var title: String {
        switch self {
        case .copy: return "Копировать"
        case .move: return "Переместить"
        }
    }

    /// Нужно ли удалять оригинал на устройстве после успешной загрузки.
    ///
    /// Транслируется в опцию `ICDeleteAfterSuccessfulDownload` при вызове
    /// `requestDownloadFile(_:options:...)`.
    public var deletesSourceAfterDownload: Bool {
        self == .move
    }
}
