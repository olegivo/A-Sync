import Foundation
import Shared

// Единственный файл, где Swift-код напрямую обращается к KMP-модулю `Shared`.
// Здесь сосредоточен весь Kotlin↔Swift-интероп, чтобы остальной код приложения
// зависел только от Swift-дружественных обёрток и стабильного типа `TransferMode`.
//
// Замечания по мостингу Kotlin/Native → Swift:
//   * companion-объект доступен как `TransferMode.companion`;
//   * сгенерированный аксессор `TransferMode.copy` НЕ используем — имя `copy` конфликтует
//     с `NSObject.copy()`; варианты получаем через `companion.fromId(...)`;
//   * Kotlin `Int` отображается в Swift `Int32` (см. инициализатор ImportResult).

extension TransferMode {
    // Доступ к вариантам через companion.fromId, а не через сгенерированные
    // статические аксессоры `.copy`/`.move`: имя `copy` конфликтует с `NSObject.copy()`
    // в мостинге Kotlin/Native → Swift.
    static var copyMode: TransferMode { TransferMode.companion.fromId(id: "copy") }
    static var moveMode: TransferMode { TransferMode.companion.fromId(id: "move") }

    /// Порядок отображения режимов в UI (замена отсутствующего CaseIterable).
    static var uiCases: [TransferMode] { [copyMode, moveMode] }
}

/// Swift-дружественный фасад над общей логикой из `Shared`.
enum SharedLogic {

    private static let resolver = FilenameResolver()
    private static let dateFilter = DateFilter()

    /// Проходит ли файл фильтр «только новые» (обёртка над Kotlin `DateFilter`).
    ///
    /// - Parameters:
    ///   - creationDate: Дата создания файла (nil — неизвестна).
    ///   - now: Момент отсчёта (обычно текущее время).
    ///   - maxAgeDays: Порог в днях; `0` — фильтр выключен.
    static func shouldInclude(creationDate: Date?, now: Date, maxAgeDays: Int) -> Bool {
        // «Дата неизвестна → включаем» решаем на стороне Swift, чтобы не боксить в KotlinLong.
        guard maxAgeDays > 0 else { return true }
        guard let creationDate else { return true }
        return dateFilter.isWithinWindow(
            creationEpochMillis: Int64((creationDate.timeIntervalSince1970 * 1000).rounded()),
            nowEpochMillis: Int64((now.timeIntervalSince1970 * 1000).rounded()),
            maxAgeDays: Int32(maxAgeDays)
        )
    }

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
