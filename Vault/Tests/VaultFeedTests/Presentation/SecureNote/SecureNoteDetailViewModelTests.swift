import Foundation
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class SecureNoteDetailViewModelTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let editor = MockSecureNoteDetailEditor()
        _ = makeSUT(editor: editor)

        XCTAssertEqual(editor.operationsPerformed, [])
    }

    @MainActor
    func test_init_editingModelUsesInitialData() {
        let note = SecureNote(title: "my title", contents: "my contents")
        let metadata = uniqueStoredMetadata(userDescription: "my description")
        let sut = makeSUT(storedNote: note, storedMetadata: metadata)

        XCTAssertEqual(sut.editingModel.detail.title, note.title)
        XCTAssertEqual(sut.editingModel.detail.contents, note.contents)
        XCTAssertEqual(sut.editingModel.detail.description, metadata.userDescription)
    }

    @MainActor
    func test_isInEditMode_initiallyFalse() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isInEditMode)
    }

    @MainActor
    func test_startEditing_setsEditModeTrue() {
        let sut = makeSUT()

        sut.startEditing()

        XCTAssertTrue(sut.isInEditMode)
    }

    @MainActor
    func test_isSaving_isInitiallyFalse() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isSaving)
    }
}

extension SecureNoteDetailViewModelTests {
    @MainActor
    private func makeSUT(
        storedNote: SecureNote = anyStoredNote(),
        storedMetadata: StoredVaultItem.Metadata = uniqueStoredMetadata(),
        editor: MockSecureNoteDetailEditor = MockSecureNoteDetailEditor()
    ) -> SecureNoteDetailViewModel {
        SecureNoteDetailViewModel(storedNote: storedNote, storedMetadata: storedMetadata, editor: editor)
    }
}
