package com.async.shared

import kotlin.test.Test
import kotlin.test.assertEquals

class FilenameResolverTest {

    private val resolver = FilenameResolver()

    @Test
    fun returnsProposedWhenFree() {
        assertEquals("IMG_0001.HEIC", resolver.uniqueFilename("IMG_0001.HEIC", emptySet()))
    }

    @Test
    fun appendsSuffixOnCollision() {
        assertEquals(
            "IMG_0001-1.HEIC",
            resolver.uniqueFilename("IMG_0001.HEIC", setOf("IMG_0001.HEIC"))
        )
    }

    @Test
    fun skipsTakenSuffixes() {
        val existing = setOf("IMG_0001.HEIC", "IMG_0001-1.HEIC", "IMG_0001-2.HEIC")
        assertEquals("IMG_0001-3.HEIC", resolver.uniqueFilename("IMG_0001.HEIC", existing))
    }

    @Test
    fun handlesFilenameWithoutExtension() {
        assertEquals("movie-1", resolver.uniqueFilename("movie", setOf("movie")))
    }

    @Test
    fun preservesExtension() {
        assertEquals("clip-1.mov", resolver.uniqueFilename("clip.mov", setOf("clip.mov")))
    }

    @Test
    fun caseSensitiveModeTreatsDifferentCaseAsFree() {
        // По умолчанию (регистрозависимо) имя в другом регистре не считается конфликтом.
        assertEquals("IMG.JPG", resolver.uniqueFilename("IMG.JPG", setOf("img.jpg")))
    }

    @Test
    fun caseInsensitiveModeDetectsCollisionAcrossCase() {
        // На регистронезависимом томе img.jpg и IMG.JPG — один файл → нужен суффикс.
        assertEquals(
            "IMG-1.JPG",
            resolver.uniqueFilename("IMG.JPG", setOf("img.jpg"), caseInsensitive = true)
        )
    }

    @Test
    fun caseInsensitiveModeSkipsTakenSuffixAcrossCase() {
        val existing = setOf("img.jpg", "img-1.jpg")
        assertEquals(
            "IMG-2.JPG",
            resolver.uniqueFilename("IMG.JPG", existing, caseInsensitive = true)
        )
    }

    @Test
    fun caseInsensitiveModeReturnsProposedWhenTrulyFree() {
        assertEquals(
            "IMG.JPG",
            resolver.uniqueFilename("IMG.JPG", setOf("other.png"), caseInsensitive = true)
        )
    }

    @Test
    fun leadingDotTreatedAsNameNotExtension() {
        // ".gitignore" — точка в начале, расширения нет.
        assertEquals(".gitignore-1", resolver.uniqueFilename(".gitignore", setOf(".gitignore")))
    }
}
