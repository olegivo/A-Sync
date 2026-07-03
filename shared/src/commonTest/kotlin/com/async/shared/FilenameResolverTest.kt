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
    fun caseSensitivity() {
        // Занятое имя в другом регистре не считается конфликтом.
        assertEquals("IMG.JPG", resolver.uniqueFilename("IMG.JPG", setOf("img.jpg")))
    }

    @Test
    fun leadingDotTreatedAsNameNotExtension() {
        // ".gitignore" — точка в начале, расширения нет.
        assertEquals(".gitignore-1", resolver.uniqueFilename(".gitignore", setOf(".gitignore")))
    }
}
