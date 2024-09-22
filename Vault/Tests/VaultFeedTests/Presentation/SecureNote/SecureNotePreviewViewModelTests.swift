import Foundation
import TestHelpers
import VaultFeed
import XCTest

final class SecureNotePreviewViewModelTests: XCTestCase {
    func test_visibleTitle_isPlaceholderEmptyTitleIfTitleEmpty() {
        let sut = SecureNotePreviewViewModel(
            title: "",
            description: "description",
            color: .default,
            isLocked: false,
            textFormat: .plain
        )

        XCTAssertEqual(sut.visibleTitle, "Untitled Note")
    }

    func test_visibleTitle_isUserDefinedTitleIfTitleNotEmpty() {
        let sut = SecureNotePreviewViewModel(
            title: "title",
            description: "description",
            color: .default,
            isLocked: false,
            textFormat: .plain
        )

        XCTAssertEqual(sut.visibleTitle, "title")
    }
}
