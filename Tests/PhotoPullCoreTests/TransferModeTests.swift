import XCTest
@testable import PhotoPullCore

final class TransferModeTests: XCTestCase {

    func testCopyDoesNotDeleteSource() {
        XCTAssertFalse(TransferMode.copy.deletesSourceAfterDownload)
    }

    func testMoveDeletesSource() {
        XCTAssertTrue(TransferMode.move.deletesSourceAfterDownload)
    }

    func testRawValueRoundTrip() {
        for mode in TransferMode.allCases {
            XCTAssertEqual(TransferMode(rawValue: mode.rawValue), mode)
        }
    }
}

final class ImportResultTests: XCTestCase {

    func testEmptySummary() {
        XCTAssertEqual(ImportResult().summary, "Нет файлов для импорта")
    }

    func testSuccessSummary() {
        XCTAssertEqual(ImportResult(succeeded: 3, failed: 0).summary, "Импортировано файлов: 3")
    }

    func testMixedSummary() {
        XCTAssertEqual(ImportResult(succeeded: 2, failed: 1).summary, "Импортировано: 2, с ошибкой: 1")
    }

    func testTotal() {
        XCTAssertEqual(ImportResult(succeeded: 4, failed: 2).total, 6)
    }
}
