import Foundation
import FoundationExtensions
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class OTPCodeDetailViewModelTests: XCTestCase {
    @MainActor
    func test_init_creatingHasNoSideEffects() {
        let editor = MockOTPCodeDetailEditor()
        _ = makeSUTCreating(editor: editor)

        XCTAssertEqual(editor.operationsPerformed, [])
    }

    @MainActor
    func test_init_editingHasNoSideEffects() {
        let editor = MockOTPCodeDetailEditor()
        _ = makeSUTEditing(editor: editor)

        XCTAssertEqual(editor.operationsPerformed, [])
    }

    @MainActor
    func test_init_creatingSetsPlaceholderInitialData() {
        let sut = makeSUTCreating()

        XCTAssertEqual(sut.editingModel.detail.issuerTitle, "")
        XCTAssertEqual(sut.editingModel.detail.accountNameTitle, "")
        XCTAssertEqual(sut.editingModel.detail.description, "")
        XCTAssertEqual(sut.editingModel.detail.algorithm, .sha1)
        XCTAssertEqual(sut.editingModel.detail.codeType, .totp)
        XCTAssertEqual(sut.editingModel.detail.hotpCounterValue, 0)
        XCTAssertEqual(sut.editingModel.detail.totpPeriodLength, 30)
        XCTAssertEqual(sut.editingModel.detail.secretBase32String, "")
    }

    @MainActor
    func test_init_editingModelUsesInitialData() {
        let code = OTPAuthCode(
            type: .totp(),
            data: .init(
                secret: .init(data: Data(), format: .base32),
                accountName: "my account",
                issuer: "my issuer"
            )
        )
        let metadata = uniqueStoredMetadata(userDescription: "my description")

        let sut = makeSUTEditing(code: code, metadata: metadata)

        XCTAssertEqual(sut.editingModel.detail.accountNameTitle, "my account")
        XCTAssertEqual(sut.editingModel.detail.issuerTitle, "my issuer")
        XCTAssertEqual(sut.editingModel.detail.description, "my description")
    }

    @MainActor
    func test_detailMenuItems_editingHasOneExpectedItem() {
        let sut = makeSUTEditing()

        XCTAssertEqual(sut.detailMenuItems.count, 1)
    }

    @MainActor
    func test_detailMenuItems_creatingHasNoItems() {
        let sut = makeSUTCreating()

        XCTAssertEqual(sut.detailMenuItems.count, 0)
    }

    @MainActor
    func test_isInEditMode_creatingInitiallyFalse() {
        let sut = makeSUTCreating()

        XCTAssertFalse(sut.isInEditMode, "Call startEditing manually!")
    }

    @MainActor
    func test_isInEditMode_editingInitiallyFalse() {
        let sut = makeSUTEditing()

        XCTAssertFalse(sut.isInEditMode)
    }

    @MainActor
    func test_startEditing_setsEditModeTrue() async throws {
        let sut = makeSUTEditing()

        sut.startEditing()

        XCTAssertTrue(sut.isInEditMode)
    }

    @MainActor
    func test_isSaving_initiallyFalse() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isSaving)
    }

    @MainActor
    func test_saveChanges_creatingUpdatesEditor() async throws {
        let editor = MockOTPCodeDetailEditor()
        let sut = makeSUTCreating(editor: editor)

        let exp = expectation(description: "Wait for code creation")
        editor.createCodeCalled = { _ in
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
        let editor = MockOTPCodeDetailEditor()
        editor.createCodeResult = .failure(anyNSError())
        let sut = makeSUTCreating(editor: editor)

        let publisher = sut.didEncounterErrorPublisher().collectFirst(1)
        let output = try await awaitPublisher(publisher) {
            await sut.saveChanges()
        }

        XCTAssertEqual(output.count, 1)
    }

    @MainActor
    func test_saveChanges_creatingSetsSavingToFalseAfterSaveError() async throws {
        let editor = MockOTPCodeDetailEditor()
        editor.createCodeResult = .failure(anyNSError())
        let sut = makeSUTCreating(editor: editor)

        await sut.saveChanges()

        XCTAssertFalse(sut.isSaving)
    }

    @MainActor
    func test_saveChanges_editingPersistsEditingModelIfSuccessful() async throws {
        let sut = makeSUTEditing()
        makeDirty(sut: sut)

        await sut.saveChanges()

        XCTAssertFalse(sut.editingModel.isDirty)
    }

    @MainActor
    func test_saveChanges_editingSetsSavingToFalseAfterSaveError() async throws {
        let editor = MockOTPCodeDetailEditor()
        editor.updateCodeResult = .failure(anyNSError())
        let sut = makeSUTEditing(editor: editor)

        await sut.saveChanges()

        XCTAssertFalse(sut.isSaving)
    }

    @MainActor
    func test_saveChanges_editingDoesNotPersistEditingModelIfSaveFailed() async throws {
        let editor = MockOTPCodeDetailEditor()
        editor.updateCodeResult = .failure(anyNSError())
        let sut = makeSUTEditing(editor: editor)
        makeDirty(sut: sut)

        await sut.saveChanges()

        XCTAssertTrue(sut.editingModel.isDirty)
    }

    @MainActor
    func test_saveChanges_editingSendsErrorIfSaveError() async throws {
        let editor = MockOTPCodeDetailEditor()
        editor.updateCodeResult = .failure(anyNSError())
        let sut = makeSUTEditing(editor: editor)

        let publisher = sut.didEncounterErrorPublisher().collectFirst(1)
        let output = try await awaitPublisher(publisher) {
            await sut.saveChanges()
        }

        XCTAssertEqual(output.count, 1)
    }

    @MainActor
    func test_deleteCode_hasNoActionIfCreatingCode() async throws {
        let editor = MockOTPCodeDetailEditor()
        let sut = makeSUTCreating(editor: editor)

        await sut.delete()

        XCTAssertEqual(editor.operationsPerformed, [])
    }

    @MainActor
    func test_deleteCode_editingIsSavingSetsBackToFalseAfterSuccessfulDelete() async throws {
        let sut = makeSUTEditing()

        await sut.deleteCode()

        XCTAssertFalse(sut.isSaving)
    }

    @MainActor
    func test_deleteCode_editingSendsFinishSignalOnSuccessfulDeletion() async throws {
        let sut = makeSUTEditing()

        let publisher = sut.isFinishedPublisher().collectFirst(1)
        let output: [Void] = try await awaitPublisher(publisher) {
            await sut.deleteCode()
        }

        XCTAssertEqual(output.count, 1)
    }

    @MainActor
    func test_deleteCode_editingSendsErrorIfDeleteError() async throws {
        let editor = MockOTPCodeDetailEditor()
        editor.deleteCodeResult = .failure(anyNSError())
        let sut = makeSUTEditing(editor: editor)

        let publisher = sut.didEncounterErrorPublisher().collectFirst(1)
        let output = try await awaitPublisher(publisher) {
            await sut.deleteCode()
        }

        XCTAssertEqual(output.count, 1)
    }

    @MainActor
    func test_done_restoresInitialEditingStateIfInEditMode() async throws {
        let sut = makeSUT()
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
        var code = uniqueCode()
        code.data.accountName = "account name test"
        code.data.issuer = "issuer test"
        var metadata = uniqueStoredMetadata()
        metadata.userDescription = "description test"
        let sut = makeSUTEditing(code: code, metadata: metadata)

        let editing = sut.editingModel

        XCTAssertEqual(editing.initialDetail.accountNameTitle, "account name test")
        XCTAssertEqual(editing.initialDetail.issuerTitle, "issuer test")
        XCTAssertEqual(editing.initialDetail.description, "description test")
    }

    @MainActor
    func test_editingModel_editingStateUsesData() {
        var code = uniqueCode()
        code.data.accountName = "account name test"
        code.data.issuer = "issuer test"
        var metadata = uniqueStoredMetadata()
        metadata.userDescription = "description test"
        let sut = makeSUTEditing(code: code, metadata: metadata)

        let editing = sut.editingModel

        XCTAssertEqual(editing.detail.accountNameTitle, "account name test")
        XCTAssertEqual(editing.detail.issuerTitle, "issuer test")
        XCTAssertEqual(editing.detail.description, "description test")
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
    func test_visibleIssuerTitle_isPlaceholderIfIssuerEmptyString() {
        let sut = makeSUT()
        sut.editingModel.detail.issuerTitle = ""

        XCTAssertEqual(sut.visibleIssuerTitle, "Unnamed")
    }

    @MainActor
    func test_visibleIssuerTitle_isUserDefinedTitleIfNotEmptyString() {
        let sut = makeSUT()
        sut.editingModel.detail.issuerTitle = "my issuer"

        XCTAssertEqual(sut.visibleIssuerTitle, "my issuer")
    }
}

extension OTPCodeDetailViewModelTests {
    @MainActor
    private func makeSUTCreating(
        editor: MockOTPCodeDetailEditor = MockOTPCodeDetailEditor(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OTPCodeDetailViewModel {
        let sut = OTPCodeDetailViewModel(mode: .creating, editor: editor)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(editor, file: file, line: line)
        return sut
    }

    @MainActor
    private func makeSUTEditing(
        code: OTPAuthCode = uniqueCode(),
        metadata: StoredVaultItem.Metadata = uniqueStoredMetadata(),
        editor: MockOTPCodeDetailEditor = MockOTPCodeDetailEditor(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OTPCodeDetailViewModel {
        let sut = OTPCodeDetailViewModel(mode: .editing(code: code, metadata: metadata), editor: editor)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(editor, file: file, line: line)
        return sut
    }

    @MainActor
    private func makeSUT(
        code: OTPAuthCode = uniqueCode(),
        metadata: StoredVaultItem.Metadata = uniqueStoredMetadata(),
        editor: MockOTPCodeDetailEditor = MockOTPCodeDetailEditor(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OTPCodeDetailViewModel {
        let sut = OTPCodeDetailViewModel(mode: .editing(code: code, metadata: metadata), editor: editor)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(editor, file: file, line: line)
        return sut
    }

    @MainActor
    func makeDirty(sut: OTPCodeDetailViewModel) {
        sut.editingModel.detail.accountNameTitle = UUID().uuidString
        XCTAssertTrue(sut.editingModel.isDirty)
    }
}
