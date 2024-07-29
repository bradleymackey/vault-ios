import Foundation
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class SecureNoteDetailViewModelTests: XCTestCase {
    @MainActor
    func test_init_creatingHasNoSideEffects() {
        let editor = SecureNoteDetailEditorMock()
        _ = makeSUTCreating(editor: editor)

        editor.assertNoOperationsPerformed()
    }

    @MainActor
    func test_init_editingHasNoSideEffects() {
        let editor = SecureNoteDetailEditorMock()
        _ = makeSUTEditing(editor: editor)

        editor.assertNoOperationsPerformed()
    }

    @MainActor
    func test_init_editingModelUsesInitialData() {
        let note = SecureNote(title: "my title", contents: "my contents")
        let metadata = anyVaultItemMetadata(userDescription: "my description")
        let sut = makeSUTEditing(storedNote: note, storedMetadata: metadata)

        XCTAssertEqual(sut.editingModel.detail.title, note.title)
        XCTAssertEqual(sut.editingModel.detail.contents, note.contents)
        XCTAssertEqual(sut.editingModel.detail.description, metadata.userDescription)
    }

    @MainActor
    func test_init_creatingSetsBlankInitialData() {
        let sut = makeSUTCreating()

        XCTAssertEqual(sut.editingModel.detail.title, "")
        XCTAssertEqual(sut.editingModel.detail.contents, "")
        XCTAssertEqual(sut.editingModel.detail.description, "")
    }

    @MainActor
    func test_isInEditMode_editingInitiallyFalse() {
        let sut = makeSUTEditing()

        XCTAssertFalse(sut.isInEditMode)
    }

    @MainActor
    func test_isInEditMode_creatingInitiallyFalse() {
        let sut = makeSUTCreating()

        XCTAssertFalse(sut.isInEditMode, "Call startEditing manually!")
    }

    @MainActor
    func test_startEditing_setsEditModeTrue() {
        let sut = makeSUTEditing()

        sut.startEditing()

        XCTAssertTrue(sut.isInEditMode)
    }

    @MainActor
    func test_isSaving_isInitiallyFalse() {
        let sut = makeSUTEditing()

        XCTAssertFalse(sut.isSaving)
    }

    @MainActor
    func test_saveChanges_creatingUpdatesEditor() async throws {
        let editor = SecureNoteDetailEditorMock()
        let sut = makeSUTCreating(editor: editor)

        let exp = expectation(description: "Wait for note creation")
        editor.createNoteHandler = { _ in
            exp.fulfill()
        }

        await sut.saveChanges()

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_saveChanges_creatingDoesNotPersistEditingModelWhenSuccessful() async throws {
        let sut = makeSUTCreating()
        makeDirty(sut: sut)

        await sut.saveChanges()

        XCTAssertTrue(sut.editingModel.isDirty)
    }

    @MainActor
    func test_saveChanges_creatingFinishesAfterCreation() async throws {
        let sut = makeSUTCreating()

        let publisher = sut.isFinishedPublisher().collectFirst(1)
        let output: [Void] = try await awaitPublisher(publisher) {
            await sut.saveChanges()
        }

        XCTAssertEqual(output.count, 1)
    }

    @MainActor
    func test_saveChanges_creatingSendsErrorIfSaveError() async throws {
        let editor = SecureNoteDetailEditorMock()
        editor.createNoteHandler = { _ in
            throw anyNSError()
        }
        let sut = makeSUTCreating(editor: editor)

        let publisher = sut.didEncounterErrorPublisher().collectFirst(1)
        let output = try await awaitPublisher(publisher) {
            await sut.saveChanges()
        }

        XCTAssertEqual(output.count, 1)
    }

    @MainActor
    func test_saveChanges_creatingSetsSavingToFalseAfterSaveError() async throws {
        let editor = SecureNoteDetailEditorMock()
        editor.createNoteHandler = { _ in
            throw anyNSError()
        }
        let sut = makeSUTCreating(editor: editor)

        await sut.saveChanges()

        XCTAssertFalse(sut.isSaving)
    }

    @MainActor
    func test_saveChanges_updatesEditor() async throws {
        let editor = SecureNoteDetailEditorMock()
        let sut = makeSUTEditing(editor: editor)

        let exp = expectation(description: "Wait for note creation")
        editor.updateNoteHandler = { _, _, _ in
            exp.fulfill()
        }

        await sut.saveChanges()

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_saveChanges_persistsEditingModelIfSuccessful() async throws {
        let sut = makeSUTEditing()
        makeDirty(sut: sut)

        await sut.saveChanges()

        XCTAssertFalse(sut.editingModel.isDirty)
    }

    @MainActor
    func test_saveChanges_setsSavingToFalseAfterSaveError() async throws {
        let editor = SecureNoteDetailEditorMock()
        editor.updateNoteHandler = { _, _, _ in
            throw anyNSError()
        }
        let sut = makeSUTEditing(editor: editor)

        await sut.saveChanges()

        XCTAssertFalse(sut.isSaving)
    }

    @MainActor
    func test_saveChanges_doesNotPersistEditingModelIfSaveFailed() async throws {
        let editor = SecureNoteDetailEditorMock()
        editor.updateNoteHandler = { _, _, _ in
            throw anyNSError()
        }
        let sut = makeSUTEditing(editor: editor)
        makeDirty(sut: sut)

        await sut.saveChanges()

        XCTAssertTrue(sut.editingModel.isDirty)
    }

    @MainActor
    func test_saveChanges_sendsErrorIfSaveError() async throws {
        let editor = SecureNoteDetailEditorMock()
        editor.updateNoteHandler = { _, _, _ in
            throw anyNSError()
        }
        let sut = makeSUTEditing(editor: editor)

        let publisher = sut.didEncounterErrorPublisher().collectFirst(1)
        let output = try await awaitPublisher(publisher) {
            await sut.saveChanges()
        }

        XCTAssertEqual(output.count, 1)
    }

    @MainActor
    func test_deleteNote_hasNoActionIfCreatingNote() async throws {
        let editor = SecureNoteDetailEditorMock()
        let sut = makeSUTCreating(editor: editor)

        await sut.deleteNote()

        editor.assertNoOperationsPerformed()
    }

    @MainActor
    func test_deleteNote_isSavingSetsBackToFalseAfterSuccessfulDelete() async throws {
        let sut = makeSUTEditing()

        await sut.deleteNote()

        XCTAssertFalse(sut.isSaving)
    }

    @MainActor
    func test_deleteNote_sendsFinishSignalOnSuccessfulDeletion() async throws {
        let sut = makeSUTEditing()

        let publisher = sut.isFinishedPublisher().collectFirst(1)
        let output: [Void] = try await awaitPublisher(publisher) {
            await sut.deleteNote()
        }

        XCTAssertEqual(output.count, 1)
    }

    @MainActor
    func test_deleteNote_sendsErrorIfDeleteError() async throws {
        let editor = SecureNoteDetailEditorMock()
        editor.deleteNoteHandler = { _ in
            throw anyNSError()
        }
        let sut = makeSUTEditing(editor: editor)

        let publisher = sut.didEncounterErrorPublisher().collectFirst(1)
        let output = try await awaitPublisher(publisher) {
            await sut.deleteNote()
        }

        XCTAssertEqual(output.count, 1)
    }

    @MainActor
    func test_done_restoresInitialEditingStateIfInEditMode() async throws {
        let sut = makeSUTEditing()
        sut.startEditing()
        makeDirty(sut: sut)

        sut.done()

        XCTAssertFalse(sut.editingModel.isDirty)
    }

    @MainActor
    func test_done_finishesIfNotInEditMode() async throws {
        let sut = makeSUTEditing()

        let publisher = sut.isFinishedPublisher().collectFirst(1)
        let output: [Void] = try await awaitPublisher(publisher) {
            sut.done()
        }

        XCTAssertEqual(output.count, 1)
    }

    @MainActor
    func test_editingModel_initialStateUsesData() {
        var note = anySecureNote()
        note.contents = "this is my contents"
        note.title = "this is my title"
        var metadata = anyVaultItemMetadata()
        metadata.userDescription = "description test"
        let sut = makeSUTEditing(storedNote: note, storedMetadata: metadata)

        let editing = sut.editingModel

        XCTAssertEqual(editing.initialDetail.contents, note.contents)
        XCTAssertEqual(editing.initialDetail.title, note.title)
        XCTAssertEqual(editing.initialDetail.description, metadata.userDescription)
    }

    @MainActor
    func test_editingModel_editingStateUsesData() {
        var note = anySecureNote()
        note.contents = "this is my contents"
        note.title = "this is my title"
        var metadata = anyVaultItemMetadata()
        metadata.userDescription = "description test"
        let sut = makeSUTEditing(storedNote: note, storedMetadata: metadata)

        let editing = sut.editingModel

        XCTAssertEqual(editing.detail.contents, note.contents)
        XCTAssertEqual(editing.detail.title, note.title)
        XCTAssertEqual(editing.detail.description, metadata.userDescription)
    }

    @MainActor
    func test_shouldShowDeleteButton_falseForCreating() {
        let sut = makeSUTCreating()

        XCTAssertFalse(sut.shouldShowDeleteButton)
    }

    @MainActor
    func test_shouldShowDeleteButton_trueForEditing() {
        let sut = makeSUTEditing()

        XCTAssertTrue(sut.shouldShowDeleteButton)
    }

    @MainActor
    func test_visibleTitle_isPlaceholderIfUserTitleIsEmpty() {
        let sut = makeSUT()
        sut.editingModel.detail.title = ""

        XCTAssertEqual(sut.visibleTitle, "Untitled Note")
    }

    @MainActor
    func test_visibleTitle_isUserTitleIfNotEmpty() {
        let sut = makeSUT()
        sut.editingModel.detail.title = "my title"

        XCTAssertEqual(sut.visibleTitle, "my title")
    }
}

extension SecureNoteDetailViewModelTests {
    @MainActor
    private func makeSUTEditing(
        storedNote: SecureNote = anySecureNote(),
        storedMetadata: VaultItem.Metadata = anyVaultItemMetadata(),
        editor: SecureNoteDetailEditorMock = SecureNoteDetailEditorMock()
    ) -> SecureNoteDetailViewModel {
        SecureNoteDetailViewModel(
            mode: .editing(note: storedNote, metadata: storedMetadata),
            allTags: [],
            editor: editor
        )
    }

    @MainActor
    private func makeSUTCreating(
        editor: SecureNoteDetailEditorMock = SecureNoteDetailEditorMock()
    ) -> SecureNoteDetailViewModel {
        SecureNoteDetailViewModel(mode: .creating, allTags: [], editor: editor)
    }

    @MainActor
    private func makeSUT(editor: SecureNoteDetailEditorMock = SecureNoteDetailEditorMock())
        -> SecureNoteDetailViewModel
    {
        SecureNoteDetailViewModel(mode: .creating, allTags: [], editor: editor)
    }

    @MainActor
    private func makeDirty(sut: SecureNoteDetailViewModel) {
        sut.editingModel.detail.contents = UUID().uuidString
        XCTAssertTrue(sut.editingModel.isDirty)
    }
}

extension SecureNoteDetailEditorMock {
    func assertNoOperationsPerformed() {
        XCTAssertEqual(createNoteCallCount, 0)
        XCTAssertEqual(updateNoteCallCount, 0)
        XCTAssertEqual(deleteNoteCallCount, 0)
    }
}
