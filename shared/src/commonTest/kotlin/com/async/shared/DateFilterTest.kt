package com.async.shared

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DateFilterTest {

    private val filter = DateFilter()
    private val day = DateFilter.MILLIS_PER_DAY
    // Фиксированный "сейчас" для детерминированности.
    private val now = 1_000_000_000_000L

    @Test
    fun disabledFilterHasNoCutoff() {
        assertNull(filter.cutoffEpochMillis(now, 0))
        assertNull(filter.cutoffEpochMillis(now, -5))
    }

    @Test
    fun cutoffIsNowMinusDays() {
        assertEquals(now - 7 * day, filter.cutoffEpochMillis(now, 7))
    }

    @Test
    fun disabledFilterIncludesEverything() {
        // Даже очень старый файл проходит, когда фильтр выключен.
        assertTrue(filter.shouldInclude(now - 100 * day, now, 0))
        assertTrue(filter.shouldInclude(null, now, 0))
    }

    @Test
    fun includesFileNewerThanCutoff() {
        assertTrue(filter.shouldInclude(now - 1 * day, now, 7))
    }

    @Test
    fun excludesFileOlderThanCutoff() {
        assertFalse(filter.shouldInclude(now - 10 * day, now, 7))
    }

    @Test
    fun includesFileExactlyAtCutoff() {
        val cutoff = filter.cutoffEpochMillis(now, 7)!!
        assertTrue(filter.shouldInclude(cutoff, now, 7))
    }

    @Test
    fun excludesFileJustBeforeCutoff() {
        val cutoff = filter.cutoffEpochMillis(now, 7)!!
        assertFalse(filter.shouldInclude(cutoff - 1, now, 7))
    }

    @Test
    fun includesFileWithUnknownDateWhenFilterEnabled() {
        assertTrue(filter.shouldInclude(null, now, 7))
    }

    @Test
    fun isWithinWindowDisabledIncludesAll() {
        assertTrue(filter.isWithinWindow(now - 100 * day, now, 0))
    }

    @Test
    fun isWithinWindowRespectsCutoff() {
        assertTrue(filter.isWithinWindow(now - 1 * day, now, 7))
        assertFalse(filter.isWithinWindow(now - 10 * day, now, 7))
    }
}
