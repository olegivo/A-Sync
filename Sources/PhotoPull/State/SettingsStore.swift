import Foundation
import Shared

/// Персистентное хранилище настроек приложения.
///
/// Путь назначения сохраняется как security-scoped bookmark — это необходимо, чтобы
/// доступ к выбранной пользователем папке сохранялся между запусками в песочнице.
final class SettingsStore {

    private let defaults: UserDefaults

    private enum Key {
        static let destinationBookmark = "destinationBookmark"
        static let transferMode = "transferMode"
        static let filterDaysBack = "filterDaysBack"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var transferMode: TransferMode {
        get {
            SharedLogic.transferMode(fromId: defaults.string(forKey: Key.transferMode))
        }
        set {
            defaults.set(newValue.id, forKey: Key.transferMode)
        }
    }

    /// Порог фильтра «только новые файлы» в днях. `0` — фильтр выключен.
    var filterDaysBack: Int {
        get { max(0, defaults.integer(forKey: Key.filterDaysBack)) }
        set { defaults.set(max(0, newValue), forKey: Key.filterDaysBack) }
    }

    /// Восстанавливает URL папки назначения из сохранённой закладки.
    ///
    /// Вызывающая сторона отвечает за баланс `startAccessingSecurityScopedResource()` /
    /// `stopAccessingSecurityScopedResource()` вокруг фактической записи.
    func loadDestinationURL() -> URL? {
        guard let data = defaults.data(forKey: Key.destinationBookmark) else { return nil }

        var isStale = false
        let url = try? URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        // Если закладка устарела, пересоздаём её на основе разрешённого URL.
        if isStale, let url {
            saveDestinationURL(url)
        }
        return url
    }

    func saveDestinationURL(_ url: URL) {
        let data = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        defaults.set(data, forKey: Key.destinationBookmark)
    }
}
