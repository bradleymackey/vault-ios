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

    func test_isValid_invalidForOnlySearchNotSearching() {
        var sut = SecureNoteDetailEdits.new()
        sut.title = " A "
        sut.visibility = .onlySearch
        sut.searchableLevel = .none

        XCTAssertFalse(sut.isValid)
    }

    func test_isValid_validForSearchCombinations() {
        var sut = SecureNoteDetailEdits.new()
        sut.title = " A "
        sut.visibility = .onlySearch
        sut.searchableLevel = .full

        XCTAssertTrue(sut.isValid)
    }
}
