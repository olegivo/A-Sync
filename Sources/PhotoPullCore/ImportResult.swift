import Foundation

/// Итог операции импорта — используется для отображения сводки в UI и в тестах.
public struct ImportResult: Equatable, Sendable {
    public var succeeded: Int
    public var failed: Int

    public init(succeeded: Int = 0, failed: Int = 0) {
        self.succeeded = succeeded
        self.failed = failed
    }

    public var total: Int { succeeded + failed }

    public var isEmpty: Bool { total == 0 }

    /// Короткое человекочитаемое описание для UI.
    public var summary: String {
        if isEmpty {
            return "Нет файлов для импорта"
        }
        if failed == 0 {
            return "Импортировано файлов: \(succeeded)"
        }
        return "Импортировано: \(succeeded), с ошибкой: \(failed)"
    }
}
