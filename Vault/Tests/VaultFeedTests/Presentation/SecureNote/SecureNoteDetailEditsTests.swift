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
}
