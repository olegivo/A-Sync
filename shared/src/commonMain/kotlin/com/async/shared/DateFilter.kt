package com.async.shared

/**
 * Фильтр «только новые файлы» по дате создания.
 *
 * Правило: копировать только файлы, дата создания которых новее, чем `сейчас - N дней`
 * (скользящее окно относительно момента импорта).
 *
 * Чистая логика без зависимостей от платформы — тестируется на JVM/Linux (×1).
 * Все моменты времени — в миллисекундах от эпохи (Unix epoch, UTC).
 */
class DateFilter {

    companion object {
        const val MILLIS_PER_DAY: Long = 24L * 60L * 60L * 1000L
    }

    /**
     * Нижняя граница (включительно) для даты создания.
     *
     * @param nowEpochMillis Текущий момент.
     * @param maxAgeDays Сколько дней назад считать файл «новым». `<= 0` — фильтр выключен.
     * @return Момент отсечки или `null`, если фильтрация не нужна.
     */
    fun cutoffEpochMillis(nowEpochMillis: Long, maxAgeDays: Int): Long? {
        if (maxAgeDays <= 0) return null
        return nowEpochMillis - maxAgeDays.toLong() * MILLIS_PER_DAY
    }

    /**
     * Нужно ли включать файл в импорт.
     *
     * @param creationEpochMillis Дата создания файла; `null` — дата неизвестна.
     * @param nowEpochMillis Текущий момент.
     * @param maxAgeDays Порог в днях; `<= 0` — фильтр выключен (берём всё).
     * @return `true`, если файл проходит фильтр.
     *
     * Замечания:
     *  * при выключенном фильтре включаются все файлы;
     *  * если дата создания неизвестна — файл включается (безопасное поведение: не терять данные).
     */
    fun shouldInclude(creationEpochMillis: Long?, nowEpochMillis: Long, maxAgeDays: Int): Boolean {
        val cutoff = cutoffEpochMillis(nowEpochMillis, maxAgeDays) ?: return true
        if (creationEpochMillis == null) return true
        return creationEpochMillis >= cutoff
    }
}
