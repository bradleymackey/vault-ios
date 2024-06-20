import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class SecureNoteDetailEditsTests: XCTestCase {
    func test_isValid_invalidForEmptyTitle() {
        let sut = SecureNoteDetailEdits(title: "")

        XCTAssertFalse(sut.isValid)
    }

    func test_isValid_invalidForBlankTitle() {
        let sut = SecureNoteDetailEdits(title: "  ")

        XCTAssertFalse(sut.isValid)
    }

    func test_isValid_validForTitleWithContents() {
        let sut = SecureNoteDetailEdits(title: " A ")

        XCTAssertTrue(sut.isValid)
    }

    func test_isValid_invalidForOnlySearchNotSearching() {
        var sut = SecureNoteDetailEdits(title: " A ")
        sut.visibility = .onlySearch
        sut.searchableLevel = .none

        XCTAssertFalse(sut.isValid)
    }

    func test_isValid_validForSearchCombinations() {
        var sut = SecureNoteDetailEdits(title: " A ")
        sut.visibility = .onlySearch
        sut.searchableLevel = .full

        XCTAssertTrue(sut.isValid)
    }
}
