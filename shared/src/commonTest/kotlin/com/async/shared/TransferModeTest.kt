package com.async.shared

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class TransferModeTest {

    @Test
    fun copyDoesNotDeleteSource() {
        assertFalse(TransferMode.COPY.deletesSourceAfterDownload)
    }

    @Test
    fun moveDeletesSource() {
        assertTrue(TransferMode.MOVE.deletesSourceAfterDownload)
    }

    @Test
    fun fromIdRoundTrip() {
        for (mode in TransferMode.entries) {
            assertEquals(mode, TransferMode.fromId(mode.id))
        }
    }

    @Test
    fun fromIdDefaultsToCopy() {
        assertEquals(TransferMode.COPY, TransferMode.fromId(null))
        assertEquals(TransferMode.COPY, TransferMode.fromId("unknown"))
    }
}

class ImportResultTest {

    @Test
    fun emptySummary() {
        assertEquals("Нет файлов для импорта", ImportResult().summary)
    }

    @Test
    fun successSummary() {
        assertEquals("Импортировано файлов: 3", ImportResult(succeeded = 3).summary)
    }

    @Test
    fun mixedSummary() {
        assertEquals("Импортировано: 2, с ошибкой: 1", ImportResult(succeeded = 2, failed = 1).summary)
    }

    @Test
    fun total() {
        assertEquals(6, ImportResult(succeeded = 4, failed = 2).total)
    }
}
