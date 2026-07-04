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
     * сохраняется.
     *
     * @param proposed Желаемое имя файла (например, `IMG_0001.HEIC`).
     * @param existing Уже занятые имена в целевой папке.
     * @param caseInsensitive Если `true`, коллизии определяются без учёта регистра —
     *   это соответствует поведению регистронезависимых томов (APFS/HFS+ по умолчанию),
     *   где `img.jpg` и `IMG.JPG` — один и тот же файл. По умолчанию `false`.
     * @return Уникальное имя файла.
     */
    fun uniqueFilename(
        proposed: String,
        existing: Set<String>,
        caseInsensitive: Boolean = false
    ): String {
        // Для регистронезависимого режима сравниваем по нормализованному (нижнему) регистру.
        val taken: Set<String> = if (caseInsensitive) {
            existing.mapTo(HashSet(existing.size)) { it.lowercase() }
        } else {
            existing
        }

        fun isTaken(name: String): Boolean =
            if (caseInsensitive) name.lowercase() in taken else name in taken

        if (!isTaken(proposed)) return proposed

        val dotIndex = proposed.lastIndexOf('.')
        val hasExtension = dotIndex > 0
        val base = if (hasExtension) proposed.substring(0, dotIndex) else proposed
        val ext = if (hasExtension) proposed.substring(dotIndex + 1) else ""

        var index = 1
        while (true) {
            val candidate = if (ext.isEmpty()) "$base-$index" else "$base-$index.$ext"
            if (!isTaken(candidate)) return candidate
            index++
        }
    }
}
