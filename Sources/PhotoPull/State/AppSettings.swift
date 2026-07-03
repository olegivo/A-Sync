import Foundation
import SwiftUI
import Shared

/// Наблюдаемая модель настроек для SwiftUI.
///
/// MVP хранит ровно то, что требуется по постановке: путь назначения и режим
/// (копировать/переместить). Запуск импорта — ручной, поэтому здесь нет автозапуска.
@MainActor
final class AppSettings: ObservableObject {

    @Published private(set) var destinationURL: URL?
    @Published var transferMode: TransferMode {
        didSet { store.transferMode = transferMode }
    }

    /// Порог фильтра «только новые файлы» в днях. `0` — фильтр выключен.
    @Published var filterDaysBack: Int {
        didSet { store.filterDaysBack = filterDaysBack }
    }

    private let store: SettingsStore

    init(store: SettingsStore = SettingsStore()) {
        self.store = store
        self.destinationURL = store.loadDestinationURL()
        self.transferMode = store.transferMode
        self.filterDaysBack = store.filterDaysBack
    }

    /// Задаёт папку назначения (после выбора в NSOpenPanel).
    func setDestination(_ url: URL) {
        destinationURL = url
        store.saveDestinationURL(url)
    }

    /// Готовы ли настройки к запуску импорта.
    var isReadyToImport: Bool {
        destinationURL != nil
    }

    /// Отображаемый путь назначения.
    var destinationDisplayPath: String {
        destinationURL?.path(percentEncoded: false) ?? "Папка не выбрана"
    }

    /// Включён ли фильтр по дате.
    var isDateFilterEnabled: Bool {
        get { filterDaysBack > 0 }
        set { filterDaysBack = newValue ? max(filterDaysBack, 1) : 0 }
    }
}
