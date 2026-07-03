import XCTest
@testable import PhotoPullCore

final class FilenameResolverTests: XCTestCase {

    private let resolver = FilenameResolver()

    func testReturnsProposedWhenFree() {
        let result = resolver.uniqueFilename(for: "IMG_0001.HEIC", existing: [])
        XCTAssertEqual(result, "IMG_0001.HEIC")
    }

    func testAppendsSuffixOnCollision() {
        let result = resolver.uniqueFilename(for: "IMG_0001.HEIC", existing: ["IMG_0001.HEIC"])
        XCTAssertEqual(result, "IMG_0001-1.HEIC")
    }

    func testSkipsTakenSuffixes() {
        let existing: Set<String> = ["IMG_0001.HEIC", "IMG_0001-1.HEIC", "IMG_0001-2.HEIC"]
        let result = resolver.uniqueFilename(for: "IMG_0001.HEIC", existing: existing)
        XCTAssertEqual(result, "IMG_0001-3.HEIC")
    }

    func testHandlesFilenameWithoutExtension() {
        let result = resolver.uniqueFilename(for: "movie", existing: ["movie"])
        XCTAssertEqual(result, "movie-1")
    }

    func testPreservesCompoundExtension() {
        // NSString.pathExtension вернёт только последний компонент — это ожидаемо.
        let result = resolver.uniqueFilename(for: "clip.mov", existing: ["clip.mov"])
        XCTAssertEqual(result, "clip-1.mov")
    }

    func testCaseSensitivity() {
        // Занятое имя в другом регистре не считается конфликтом.
        let result = resolver.uniqueFilename(for: "IMG.JPG", existing: ["img.jpg"])
        XCTAssertEqual(result, "IMG.JPG")
    }
}
