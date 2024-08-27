import Foundation
import FoundationExtensions
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class OTPCodeDetailViewModelTests: XCTestCase {
    @MainActor
    func test_init_creatingHasNoSideEffects() {
        let editor = OTPCodeDetailEditorMock()
        _ = makeSUTCreating(editor: editor)

        editor.assertNoOperations()
    }

    @MainActor
    func test_init_editingHasNoSideEffects() {
        let editor = OTPCodeDetailEditorMock()
        _ = makeSUTEditing(editor: editor)

        editor.assertNoOperations()
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
    func test_init_creatingWithCodeUsesInitialData() {
        let code = OTPAuthCode(
            type: .totp(),
            data: .init(
                secret: .init(data: Data(), format: .base32),
                accountName: "my account",
                issuer: "my issuer"
            )
        )

        let sut = makeSUTCreating(initialCode: code)

        XCTAssertEqual(sut.editingModel.detail.accountNameTitle, "my account")
        XCTAssertEqual(sut.editingModel.detail.issuerTitle, "my issuer")
        XCTAssertEqual(sut.editingModel.detail.description, "")
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
        let metadata = anyVaultItemMetadata(userDescription: "my description")

        let sut = makeSUTEditing(code: code, metadata: metadata)

        XCTAssertEqual(sut.editingModel.detail.accountNameTitle, "my account")
        XCTAssertEqual(sut.editingModel.detail.issuerTitle, "my issuer")
        XCTAssertEqual(sut.editingModel.detail.description, "my description")
    }

    @MainActor
    func test_detailMenuItems_editingHasItems() {
        let sut = makeSUTEditing()

        XCTAssertEqual(
            sut.detailMenuItems.map(\.title),
            ["Created", "Visibility", "Type", "Period", "Digits", "Algorithm", "Key Format"]
        )
    }

    @MainActor
    func test_detailMenuItems_creatingHasItems() {
        let sut = makeSUTCreating()

        XCTAssertEqual(sut.detailMenuItems.map(\.title), ["Visibility"])
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
        let editor = OTPCodeDetailEditorMock()
        let sut = makeSUTCreating(editor: editor)

        let exp = expectation(description: "Wait for code creation")
        editor.createCodeHandler = { _ in
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
        let editor = OTPCodeDetailEditorMock()
        editor.createCodeHandler = { _ in
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
        let editor = OTPCodeDetailEditorMock()
        editor.createCodeHandler = { _ in
            throw anyNSError()
        }
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
        let editor = OTPCodeDetailEditorMock()
        editor.updateCodeHandler = { _, _, _ in
            throw anyNSError()
        }
        let sut = makeSUTEditing(editor: editor)

        await sut.saveChanges()

        XCTAssertFalse(sut.isSaving)
    }

    @MainActor
    func test_saveChanges_editingDoesNotPersistEditingModelIfSaveFailed() async throws {
        let editor = OTPCodeDetailEditorMock()
        editor.updateCodeHandler = { _, _, _ in
            throw anyNSError()
        }
        let sut = makeSUTEditing(editor: editor)
        makeDirty(sut: sut)

        await sut.saveChanges()

        XCTAssertTrue(sut.editingModel.isDirty)
    }

    @MainActor
    func test_saveChanges_editingSendsErrorIfSaveError() async throws {
        let editor = OTPCodeDetailEditorMock()
        editor.updateCodeHandler = { _, _, _ in
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
    func test_deleteCode_hasNoActionIfCreatingCode() async throws {
        let editor = OTPCodeDetailEditorMock()
        let sut = makeSUTCreating(editor: editor)

        await sut.delete()

        editor.assertNoOperations()
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
        let editor = OTPCodeDetailEditorMock()
        editor.deleteCodeHandler = { _ in
            throw anyNSError()
        }
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
        var metadata = anyVaultItemMetadata()
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
        var metadata = anyVaultItemMetadata()
        metadata.userDescription = "description test"
        let sut = makeSUTEditing(code: code, metadata: metadata)

        let editing = sut.editingModel

        XCTAssertEqual(editing.detail.accountNameTitle, "account name test")
        XCTAssertEqual(editing.detail.issuerTitle, "issuer test")
        XCTAssertEqual(editing.detail.description, "description test")
    }

    @MainActor
    func test_editingModel_creatingWithoutCodeIsNotInitiallyDirty() {
        let sut = makeSUTCreating(initialCode: nil)

        XCTAssertFalse(
            sut.editingModel.isDirty,
            "This is not initially dirty because we need the user to input data before we can save."
        )
    }

    @MainActor
    func test_editingModel_creatingWithCodeIsInitiallyDirty() {
        let sut = makeSUTCreating(initialCode: uniqueCode())

        XCTAssertTrue(
            sut.editingModel.isDirty,
            "This is initially dirty as the data has been input from elsewhere. The initial state is hydrated with dirty data."
        )
    }

    @MainActor
    func test_editingModel_editingIsNotInitiallyDirty() {
        let sut = makeSUTEditing()

        XCTAssertFalse(sut.editingModel.isDirty)
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

    @MainActor
    func test_remainingTags_noTagsSelectedIsEqualToAllTags() {
        let tag1 = anyVaultItemTag()
        let tag2 = anyVaultItemTag()
        let tag3 = anyVaultItemTag()
        let dataModel = anyVaultDataModel()
        dataModel.allTags = [tag1, tag2, tag3]

        let sut = makeSUT(dataModel: dataModel)
        sut.editingModel.detail.tags = []

        XCTAssertEqual(sut.remainingTags, [tag1, tag2, tag3])
    }

    @MainActor
    func test_remainingTags_removesTagsThatHaveBeenSelected() {
        let tag1 = anyVaultItemTag()
        let tag2 = anyVaultItemTag()
        let tag3 = anyVaultItemTag()
        let dataModel = anyVaultDataModel()
        dataModel.allTags = [tag1, tag2, tag3]

        let sut = makeSUT(dataModel: dataModel)
        sut.editingModel.detail.tags = [tag1.id]

        XCTAssertEqual(sut.remainingTags, [tag2, tag3])
    }

    @MainActor
    func test_tagsThatAreSelected_isEmptyIfNoTagsSelected() {
        let tag1 = anyVaultItemTag()
        let tag2 = anyVaultItemTag()
        let tag3 = anyVaultItemTag()
        let dataModel = anyVaultDataModel()
        dataModel.allTags = [tag1, tag2, tag3]

        let sut = makeSUT(dataModel: dataModel)
        sut.editingModel.detail.tags = []

        XCTAssertEqual(sut.tagsThatAreSelected, [])
    }

    @MainActor
    func test_tagsThatAreSelected_matchesSelectedTags() {
        let tag1 = anyVaultItemTag()
        let tag2 = anyVaultItemTag()
        let tag3 = anyVaultItemTag()
        let dataModel = anyVaultDataModel()
        dataModel.allTags = [tag1, tag2, tag3]

        let sut = makeSUT(dataModel: dataModel)
        sut.editingModel.detail.tags = [tag1.id, tag3.id]

        XCTAssertEqual(sut.tagsThatAreSelected, [tag1, tag3])
    }
}

extension OTPCodeDetailViewModelTests {
    @MainActor
    private func makeSUTCreating(
        editor: OTPCodeDetailEditorMock = .defaultMock(),
        initialCode: OTPAuthCode? = nil,
        dataModel: VaultDataModel = VaultDataModel(
            vaultStore: VaultStoreStub(),
            vaultTagStore: VaultTagStoreStub(),
            vaultImporter: VaultStoreImporterMock(),
            vaultDeleter: VaultStoreDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock()
        ),
        allTags _: [VaultItemTag] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OTPCodeDetailViewModel {
        let sut = OTPCodeDetailViewModel(
            mode: .creating(initialCode: initialCode),
            dataModel: dataModel,
            editor: editor
        )
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(editor, file: file, line: line)
        trackForMemoryLeaks(dataModel, file: file, line: line)
        return sut
    }

    @MainActor
    private func makeSUTEditing(
        code: OTPAuthCode = uniqueCode(),
        metadata: VaultItem.Metadata = anyVaultItemMetadata(),
        editor: OTPCodeDetailEditorMock = .defaultMock(),
        dataModel: VaultDataModel = VaultDataModel(
            vaultStore: VaultStoreStub(),
            vaultTagStore: VaultTagStoreStub(),
            vaultImporter: VaultStoreImporterMock(),
            vaultDeleter: VaultStoreDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock()
        ),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OTPCodeDetailViewModel {
        let sut = OTPCodeDetailViewModel(
            mode: .editing(code: code, metadata: metadata),
            dataModel: dataModel,
            editor: editor
        )
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(editor, file: file, line: line)
        trackForMemoryLeaks(dataModel, file: file, line: line)
        return sut
    }

    @MainActor
    private func makeSUT(
        code: OTPAuthCode = uniqueCode(),
        metadata: VaultItem.Metadata = anyVaultItemMetadata(),
        editor: OTPCodeDetailEditorMock = .defaultMock(),
        dataModel: VaultDataModel = VaultDataModel(
            vaultStore: VaultStoreStub(),
            vaultTagStore: VaultTagStoreStub(),
            vaultImporter: VaultStoreImporterMock(),
            vaultDeleter: VaultStoreDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock()
        ),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OTPCodeDetailViewModel {
        let sut = OTPCodeDetailViewModel(
            mode: .editing(code: code, metadata: metadata),
            dataModel: dataModel,
            editor: editor
        )
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(editor, file: file, line: line)
        trackForMemoryLeaks(dataModel, file: file, line: line)
        return sut
    }

    @MainActor
    func makeDirty(sut: OTPCodeDetailViewModel) {
        sut.editingModel.detail.accountNameTitle = UUID().uuidString
        XCTAssertTrue(sut.editingModel.isDirty)
    }
}

extension OTPCodeDetailEditorMock {
    static func defaultMock() -> OTPCodeDetailEditorMock {
        let s = OTPCodeDetailEditorMock()
        return s
    }

    func assertNoOperations() {
        XCTAssertEqual(createCodeCallCount, 0)
        XCTAssertEqual(updateCodeCallCount, 0)
        XCTAssertEqual(deleteCodeCallCount, 0)
    }
}
