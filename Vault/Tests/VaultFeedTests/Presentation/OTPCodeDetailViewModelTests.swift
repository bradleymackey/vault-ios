import Foundation
import FoundationExtensions
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

@MainActor
final class OTPCodeDetailViewModelTests: XCTestCase {
    func test_detailMenuItems_hasOneExpectedItem() {
        let sut = makeSUT()

        XCTAssertEqual(sut.detailMenuItems.count, 1)
    }

    func test_isInEditMode_initiallyFalse() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isInEditMode)
    }

    func test_startEditing_setsEditModeTrue() async throws {
        let sut = makeSUT()

        await expectSingleMutation(observable: sut, keyPath: \.isInEditMode) {
            sut.startEditing()
        }

        XCTAssertTrue(sut.isInEditMode)
    }

    func test_isSaving_initiallyFalse() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isSaving)
    }

    func test_saveChanges_setsIsSavingToTrue() async throws {
        let completeUpdateSignal = PendingValue<Void>()
        let editor = CodeDetailEditorMock()
        editor.updateCodeCalled = { _, _, _ in
            try? await completeUpdateSignal.awaitValue()
        }

        let sut = makeSUT(editor: editor)

        let exp = expectation(description: "Wait for save changes to start")
        let task = Task {
            exp.fulfill()
            await sut.saveChanges()
        }
        await fulfillment(of: [exp], timeout: 1.0)

        XCTAssertTrue(sut.isSaving)

        // Cleanup
        await completeUpdateSignal.fulfill()
        _ = await task.value
    }

    func test_saveChanges_setsBackToFalseAfterSuccessfulSave() async throws {
        let sut = makeSUT()

        await sut.saveChanges()

        XCTAssertFalse(sut.isSaving)
    }

    func test_saveChanges_disablesEditModeIfSuccessful() async throws {
        let sut = makeSUT()

        sut.startEditing()
        await sut.saveChanges()

        XCTAssertFalse(sut.isInEditMode)
    }

    func test_saveChanges_persistsEditingModelIfSuccessful() async throws {
        let sut = makeSUT()
        sut.editingModel.detail.accountNameTitle = UUID().uuidString
        XCTAssertTrue(sut.editingModel.isDirty)

        await sut.saveChanges()

        XCTAssertFalse(sut.editingModel.isDirty)
    }

    func test_saveChanges_setsSavingToFalseAfterSaveError() async throws {
        let editor = CodeDetailEditorMock()
        editor.updateCodeResult = .failure(anyNSError())
        let sut = makeSUT(editor: editor)

        await sut.saveChanges()

        XCTAssertFalse(sut.isSaving)
    }

    func test_saveChanges_remainsInEditModeAfterSaveFailure() async throws {
        let editor = CodeDetailEditorMock()
        editor.updateCodeResult = .failure(anyNSError())
        let sut = makeSUT(editor: editor)

        sut.startEditing()
        await sut.saveChanges()

        XCTAssertTrue(sut.isInEditMode)
    }

    func test_saveChanges_doesNotPersistEditingModelIfSaveFailed() async throws {
        let editor = CodeDetailEditorMock()
        editor.updateCodeResult = .failure(anyNSError())
        let sut = makeSUT(editor: editor)
        sut.editingModel.detail.accountNameTitle = UUID().uuidString
        XCTAssertTrue(sut.editingModel.isDirty)

        await sut.saveChanges()

        XCTAssertTrue(sut.editingModel.isDirty)
    }

    func test_saveChanges_sendsErrorIfSaveError() async throws {
        let editor = CodeDetailEditorMock()
        editor.updateCodeResult = .failure(anyNSError())
        let sut = makeSUT(editor: editor)

        let publisher = sut.didEncounterErrorPublisher().collectFirst(1)
        let output = try await awaitPublisher(publisher) {
            await sut.saveChanges()
        }

        XCTAssertEqual(output.count, 1)
    }

    func test_deleteCode_setsIsSavingToTrue() async throws {
        let completeDeleteSignal = PendingValue<Void>()
        let editor = CodeDetailEditorMock()
        editor.deleteCodeCalled = { _ in
            try? await completeDeleteSignal.awaitValue()
        }

        let sut = makeSUT(editor: editor)

        let exp = expectation(description: "Wait for save changes to start")
        let task = Task {
            exp.fulfill()
            await sut.deleteCode()
        }
        await fulfillment(of: [exp], timeout: 1.0)

        XCTAssertTrue(sut.isSaving)

        // Cleanup
        await completeDeleteSignal.fulfill()
        _ = await task.value
    }

    func test_deleteCode_setsBackToFalseAfterSuccessfulDelete() async throws {
        let sut = makeSUT()

        await sut.deleteCode()

        XCTAssertFalse(sut.isSaving)
    }

    func test_deleteCode_sendsFinishSignalOnSuccessfulDeletion() async throws {
        let sut = makeSUT()

        let publisher = sut.isFinishedPublisher().collectFirst(1)
        let output: [Void] = try await awaitPublisher(publisher) {
            await sut.deleteCode()
        }

        XCTAssertEqual(output.count, 1)
    }

    func test_deleteCode_sendsErrorIfDeleteError() async throws {
        let editor = CodeDetailEditorMock()
        editor.deleteCodeResult = .failure(anyNSError())
        let sut = makeSUT(editor: editor)

        let publisher = sut.didEncounterErrorPublisher().collectFirst(1)
        let output = try await awaitPublisher(publisher) {
            await sut.deleteCode()
        }

        XCTAssertEqual(output.count, 1)
    }

    func test_done_disablesEditModeIfInEditMode() async throws {
        let sut = makeSUT()
        sut.startEditing()

        sut.done()

        XCTAssertFalse(sut.isInEditMode)
    }

    func test_done_restoresInitialEditingStateIfInEditMode() async throws {
        let sut = makeSUT()
        sut.startEditing()

        sut.editingModel.detail.accountNameTitle = UUID().uuidString
        XCTAssertTrue(sut.editingModel.isDirty)

        sut.done()

        XCTAssertFalse(sut.editingModel.isDirty)
    }

    func test_done_doesNotFinishIfInEditMode() async throws {
        let sut = makeSUT()
        sut.startEditing()

        let publisher = sut.isFinishedPublisher().collectFirst(1)
        await awaitNoPublish(publisher: publisher) {
            sut.done()
        }
    }

    func test_done_finishesIfNotInEditMode() async throws {
        let sut = makeSUT()

        let publisher = sut.isFinishedPublisher().collectFirst(1)
        let output: [Void] = try await awaitPublisher(publisher) {
            sut.done()
        }

        XCTAssertEqual(output.count, 1)
    }

    func test_editingModel_initialStateUsesData() {
        var code = uniqueCode()
        code.data.accountName = "account name test"
        code.data.issuer = "issuer test"
        var metadata = uniqueStoredMetadata()
        metadata.userDescription = "description test"
        let sut = makeSUT(code: code, metadata: metadata)

        let editing = sut.editingModel

        XCTAssertEqual(editing.initialDetail.accountNameTitle, "account name test")
        XCTAssertEqual(editing.initialDetail.issuerTitle, "issuer test")
        XCTAssertEqual(editing.initialDetail.description, "description test")
    }

    func test_editingModel_editingStateUsesData() {
        var code = uniqueCode()
        code.data.accountName = "account name test"
        code.data.issuer = "issuer test"
        var metadata = uniqueStoredMetadata()
        metadata.userDescription = "description test"
        let sut = makeSUT(code: code, metadata: metadata)

        let editing = sut.editingModel

        XCTAssertEqual(editing.detail.accountNameTitle, "account name test")
        XCTAssertEqual(editing.detail.issuerTitle, "issuer test")
        XCTAssertEqual(editing.detail.description, "description test")
    }
}

extension OTPCodeDetailViewModelTests {
    private func makeSUT(
        code: OTPAuthCode = uniqueCode(),
        metadata: StoredVaultItem.Metadata = uniqueStoredMetadata(),
        editor: CodeDetailEditorMock = CodeDetailEditorMock(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OTPCodeDetailViewModel {
        let sut = OTPCodeDetailViewModel(storedCode: code, storedMetadata: metadata, editor: editor)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(editor, file: file, line: line)
        return sut
    }

    private class CodeDetailEditorMock: OTPCodeDetailEditor {
        var updateCodeResult: Result<Void, any Error> = .success(())
        var updateCodeCalled: (UUID, OTPAuthCode, OTPCodeDetailEdits) async -> Void = { _, _, _ in }
        func update(id: UUID, item: OTPAuthCode, edits: OTPCodeDetailEdits) async throws {
            await updateCodeCalled(id, item, edits)
            try updateCodeResult.get()
        }

        var deleteCodeResult: Result<Void, any Error> = .success(())
        var deleteCodeCalled: (UUID) async -> Void = { _ in }
        func deleteCode(id: UUID) async throws {
            await deleteCodeCalled(id)
            try deleteCodeResult.get()
        }
    }
}
