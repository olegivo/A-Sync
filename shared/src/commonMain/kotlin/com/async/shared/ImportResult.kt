package com.async.shared

/**
 * Итог операции импорта — используется для отображения сводки в UI и в тестах.
 */
data class ImportResult(
    val succeeded: Int = 0,
    val failed: Int = 0
) {
    val total: Int get() = succeeded + failed

    val isEmpty: Boolean get() = total == 0

    /** Короткое человекочитаемое описание для UI. */
    val summary: String
        get() = when {
            isEmpty -> "Нет файлов для импорта"
            failed == 0 -> "Импортировано файлов: $succeeded"
            else -> "Импортировано: $succeeded, с ошибкой: $failed"
        }
}
