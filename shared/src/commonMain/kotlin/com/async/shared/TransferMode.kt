package com.async.shared

/**
 * Режим переноса медиафайлов с устройства.
 */
enum class TransferMode(
    /** Стабильный строковый идентификатор для персистентности/интеропа. */
    val id: String,
    /** Человекочитаемое название для UI. */
    val title: String
) {
    /** Копировать: файлы остаются на устройстве. */
    COPY(id = "copy", title = "Копировать"),

    /** Переместить: после успешной загрузки файл удаляется с устройства. */
    MOVE(id = "move", title = "Переместить");

    /**
     * Нужно ли удалять оригинал на устройстве после успешной загрузки.
     *
     * На стороне macOS транслируется в опцию `ICDeleteAfterSuccessfulDownload`.
     */
    val deletesSourceAfterDownload: Boolean
        get() = this == MOVE

    companion object {
        /** Разбор режима по строковому [id]; по умолчанию — [COPY]. */
        fun fromId(id: String?): TransferMode =
            entries.firstOrNull { it.id == id } ?: COPY
    }
}
