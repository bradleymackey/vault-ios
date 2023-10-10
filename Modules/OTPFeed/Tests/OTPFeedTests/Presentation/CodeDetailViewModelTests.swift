import Foundation
import FoundationExtensions
import OTPFeed
import TestHelpers
import XCTest

@MainActor
final class CodeDetailViewModelTests: XCTestCase {
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
        editor.updateCodeCalled = { _, _ in
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
        completeUpdateSignal.fulfill()
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

    func test_editingModel_initialStateUsesData() {
        var code = uniqueStoredCode()
        code.code.data.accountName = "account name test"
        code.code.data.issuer = "issuer test"
        code.userDescription = "description test"
        let sut = makeSUT(code: code)

        let editing = sut.editingModel

        XCTAssertEqual(editing.initialDetail.accountNameTitle, "account name test")
        XCTAssertEqual(editing.initialDetail.issuerTitle, "issuer test")
        XCTAssertEqual(editing.initialDetail.description, "description test")
    }

    func test_editingModel_editingStateUsesData() {
        var code = uniqueStoredCode()
        code.code.data.accountName = "account name test"
        code.code.data.issuer = "issuer test"
        code.userDescription = "description test"
        let sut = makeSUT(code: code)

        let editing = sut.editingModel

        XCTAssertEqual(editing.detail.accountNameTitle, "account name test")
        XCTAssertEqual(editing.detail.issuerTitle, "issuer test")
        XCTAssertEqual(editing.detail.description, "description test")
    }
}

extension CodeDetailViewModelTests {
    private func makeSUT(
        code: StoredOTPCode = uniqueStoredCode(),
        editor: CodeDetailEditorMock = CodeDetailEditorMock(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CodeDetailViewModel {
        let sut = CodeDetailViewModel(storedCode: code, editor: editor)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(editor, file: file, line: line)
        return sut
    }

    private class CodeDetailEditorMock: CodeDetailEditor {
        var updateCodeResult: Result<Void, Error> = .success(())
        var updateCodeCalled: (StoredOTPCode, CodeDetailEdits) async -> Void = { _, _ in }
        func update(code: StoredOTPCode, edits: CodeDetailEdits) async throws {
            await updateCodeCalled(code, edits)
            try updateCodeResult.get()
        }

        var deleteCodeResult: Result<Void, Error> = .success(())
        var deleteCodeCalled: (UUID) async -> Void = { _ in }
        func deleteCode(id: UUID) async throws {
            await deleteCodeCalled(id)
            try deleteCodeResult.get()
        }
    }
}
