import Foundation
import TestHelpers
import Testing
import VaultFeed

@Suite
struct SecureNotePreviewViewModelTests {
    @Test
    func visibleTitle_isPlaceholderEmptyTitleIfTitleEmpty() {
        let sut = SecureNotePreviewViewModel(
            title: "",
            description: "description",
            color: .default,
            isLocked: false,
            textFormat: .plain,
        )

        #expect(sut.visibleTitle == "Untitled Note")
    }

    @Test
    func visibleTitle_isUserDefinedTitleIfTitleNotEmpty() {
        let sut = SecureNotePreviewViewModel(
            title: "title",
            description: "description",
            color: .default,
            isLocked: false,
            textFormat: .plain,
        )

        #expect(sut.visibleTitle == "title")
    }
}
