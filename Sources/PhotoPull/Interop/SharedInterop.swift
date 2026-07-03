import Foundation
import Shared

// Единственный файл, где Swift-код напрямую обращается к KMP-модулю `Shared`.
// Здесь сосредоточен весь Kotlin↔Swift-интероп, чтобы остальной код приложения
// зависел только от Swift-дружественных обёрток и стабильного типа `TransferMode`.
//
// Замечания по мостингу Kotlin/Native → Swift:
//   * enum-элементы `COPY`/`MOVE` доступны как `TransferMode.copy` / `.move`;
//   * companion-объект — как `TransferMode.companion`;
//   * Kotlin `Int` отображается в Swift `Int32` (см. инициализатор ImportResult).

extension TransferMode {
    /// Порядок отображения режимов в UI (замена отсутствующего CaseIterable).
    static var uiCases: [TransferMode] { [TransferMode.copy, TransferMode.move] }
}

/// Swift-дружественный фасад над общей логикой из `Shared`.
enum SharedLogic {

    private static let resolver = FilenameResolver()

    /// Уникальное имя файла для папки назначения (обёртка над Kotlin `FilenameResolver`).
    static func uniqueFilename(_ proposed: String, existing: Set<String>) -> String {
        resolver.uniqueFilename(proposed: proposed, existing: existing)
    }

    /// Человекочитаемая сводка импорта (обёртка над Kotlin `ImportResult`).
    static func summary(succeeded: Int, failed: Int) -> String {
        ImportResult(succeeded: Int32(succeeded), failed: Int32(failed)).summary
    }

    /// Восстановление режима переноса из строкового идентификатора.
    static func transferMode(fromId id: String?) -> TransferMode {
        TransferMode.companion.fromId(id: id)
    }
}
