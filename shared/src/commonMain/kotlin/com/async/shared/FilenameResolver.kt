package com.async.shared

/**
 * Разрешение конфликтов имён при сохранении файлов в папку назначения.
 *
 * Вынесено в чистый общий код (без зависимостей от платформы), чтобы поведение можно было
 * полностью покрыть тестами и гонять их на дешёвом JVM-раннере (Linux, ×1).
 */
class FilenameResolver {

    /**
     * Возвращает имя файла, не конфликтующее с уже занятыми именами.
     *
     * Если [proposed] свободно — возвращается как есть. Иначе к базовой части имени
     * добавляется суффикс `-1`, `-2`, ... до первого свободного варианта, а расширение
     * сохраняется. Регистр учитывается так же, как в [existing].
     *
     * @param proposed Желаемое имя файла (например, `IMG_0001.HEIC`).
     * @param existing Уже занятые имена в целевой папке.
     * @return Уникальное имя файла.
     */
    fun uniqueFilename(proposed: String, existing: Set<String>): String {
        if (proposed !in existing) return proposed

        val dotIndex = proposed.lastIndexOf('.')
        val hasExtension = dotIndex > 0
        val base = if (hasExtension) proposed.substring(0, dotIndex) else proposed
        val ext = if (hasExtension) proposed.substring(dotIndex + 1) else ""

        var index = 1
        while (true) {
            val candidate = if (ext.isEmpty()) "$base-$index" else "$base-$index.$ext"
            if (candidate !in existing) return candidate
            index++
        }
    }
}
