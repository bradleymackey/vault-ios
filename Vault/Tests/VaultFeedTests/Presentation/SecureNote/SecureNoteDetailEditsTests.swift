import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class SecureNoteDetailEditsTests: XCTestCase {
    func test_isValid_invalidForEmptyTitle() {
        var sut = SecureNoteDetailEdits.new()
        sut.title = ""

        XCTAssertFalse(sut.isValid)
    }

    func test_isValid_invalidForBlankTitle() {
        var sut = SecureNoteDetailEdits.new()
        sut.title = " "

        XCTAssertFalse(sut.isValid)
    }

    func test_isValid_validForTitleWithContents() {
        var sut = SecureNoteDetailEdits.new()
        sut.title = " A "
        sut.contents = "Nice"

        XCTAssertTrue(sut.isValid)
    }

    func test_isValid_invalidForEmptySearchPassphrase() {
        var sut = SecureNoteDetailEdits.new()
        sut.title = " A "
        sut.viewConfig = .requiresSearchPassphrase
        sut.searchPassphrase = ""

        XCTAssertFalse(sut.isValid)
    }

    func test_isValid_validForNonEmptySearchPassphrase() {
        var sut = SecureNoteDetailEdits.new()
        sut.title = " A "
        sut.viewConfig = .requiresSearchPassphrase
        sut.searchPassphrase = "passphrase"

        XCTAssertTrue(sut.isValid)
    }

    func test_description_isFirstLineOfContent() {
        var sut = SecureNoteDetailEdits.new()
        sut.title = " A "
        sut.contents = "First\nSecond\nThird"

        XCTAssertEqual(sut.description, "First")
    }

    func test_isHiddenWithPassphrase_falseIfAlwaysVisible() {
        var sut = SecureNoteDetailEdits.new()
        sut.title = " A "
        sut.viewConfig = .alwaysVisible
        XCTAssertFalse(sut.isHiddenWithPassphrase)

        sut.isHiddenWithPassphrase = false
        XCTAssertEqual(sut.viewConfig, .alwaysVisible)
    }

    func test_isHiddenWithPassphrase_trueIfRequiresPassphrase() {
        var sut = SecureNoteDetailEdits.new()
        sut.title = " A "
        sut.viewConfig = .requiresSearchPassphrase
        XCTAssertTrue(sut.isHiddenWithPassphrase)

        sut.isHiddenWithPassphrase = true
        XCTAssertEqual(sut.viewConfig, .requiresSearchPassphrase)
    }
}
