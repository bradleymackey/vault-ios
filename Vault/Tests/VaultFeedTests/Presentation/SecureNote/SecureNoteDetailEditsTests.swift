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

        XCTAssertEqual(sut.title, "First")
    }

    func test_title_skipsEmptyLines() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "\n\nFirst\n\nSecond\nThird"

        XCTAssertEqual(sut.title, "First")
    }

    func test_description_isSecondLineOfContent() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "First\nSecond\nThird"

        XCTAssertEqual(sut.description, "Second")
    }

    func test_description_skipsEmptyLines() {
        var sut = SecureNoteDetailEdits.new()
        sut.contents = "\n\n\nFirst\n\n\nSecond\nThird"

        XCTAssertEqual(sut.description, "Second")
    }

    func test_isHiddenWithPassphrase_falseIfAlwaysVisible() {
        var sut = SecureNoteDetailEdits.new()
        sut.viewConfig = .alwaysVisible
        XCTAssertFalse(sut.isHiddenWithPassphrase)

        sut.isHiddenWithPassphrase = false
        XCTAssertEqual(sut.viewConfig, .alwaysVisible)
    }

    func test_isHiddenWithPassphrase_trueIfRequiresPassphrase() {
        var sut = SecureNoteDetailEdits.new()
        sut.viewConfig = .requiresSearchPassphrase
        XCTAssertTrue(sut.isHiddenWithPassphrase)

        sut.isHiddenWithPassphrase = true
        XCTAssertEqual(sut.viewConfig, .requiresSearchPassphrase)
    }
}
