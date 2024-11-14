import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class SecureNoteDetailEditsTests: XCTestCase {
    func test_isValid_validForTitleWithContents() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "Nice"

        XCTAssertTrue(sut.isValid)
    }

    func test_isValid_invalidForEmptySearchPassphrase() {
        var sut = SecureNoteDetailEdits.new()
        sut.viewConfig = .requiresSearchPassphrase
        sut.searchPassphrase = ""

        XCTAssertFalse(sut.isValid)
    }

    func test_isValid_validForNonEmptySearchPassphrase() {
        var sut = SecureNoteDetailEdits.new()
        sut.viewConfig = .requiresSearchPassphrase
        sut.searchPassphrase = "passphrase"

        XCTAssertTrue(sut.isValid)
    }

    func test_title_isFirstLineOfContent() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "First\nSecond\nThird"

        XCTAssertEqual(sut.titleLine, "First")
    }

    func test_title_skipsEmptyLines() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "\n\nFirst\n\nSecond\nThird"

        XCTAssertEqual(sut.titleLine, "First")
    }

    func test_contentPreviewLine_isSecondLineOfContent() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "First\nSecond\nThird"

        XCTAssertEqual(sut.contentPreviewLine, "Second")
    }

    func test_contentPreviewLine_isEmptyIfNoSecondLine() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "First"

        XCTAssertEqual(sut.contentPreviewLine, "")
    }

    func test_contentPreviewLine_skipsEmptyLines() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "\n\nFirst\n\nSecond\nThird"

        XCTAssertEqual(sut.contentPreviewLine, "Second")
    }

    func test_contentPreviewLine_isEmptyIfNoteEncrpyted() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "First\n\nSecond\nThird"
        sut.existingEncryptionKey = .init(key: .random(), salt: .random(count: 10), keyDervier: .testing)

        XCTAssertEqual(sut.contentPreviewLine, "")
    }

    func test_contentPreviewLine_isEmptyIfNoteAboutToBeENcrpyted() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "First\n\nSecond\nThird"
        sut.newEncryptionPassword = "password"

        XCTAssertEqual(sut.contentPreviewLine, "")
    }
}
