import Foundation
import FoundationExtensions
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class OTPCodeDetailViewModelTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let editor = MockOTPCodeDetailEditor()
        _ = makeSUT(editor: editor)

        XCTAssertEqual(editor.operationsPerformed, [])
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

        let sut = makeSUT(code: code, metadata: metadata)

        XCTAssertEqual(sut.editingModel.detail.accountNameTitle, "my account")
        XCTAssertEqual(sut.editingModel.detail.issuerTitle, "my issuer")
        XCTAssertEqual(sut.editingModel.detail.description, "my description")
    }

    @MainActor
    func test_detailMenuItems_hasOneExpectedItem() {
        let sut = makeSUT()

        XCTAssertEqual(sut.detailMenuItems.count, 1)
    }

    @MainActor
    func test_isInEditMode_initiallyFalse() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isInEditMode)
    }

    @MainActor
    func test_startEditing_setsEditModeTrue() async throws {
        let sut = makeSUT()

        sut.startEditing()

        XCTAssertTrue(sut.isInEditMode)
    }

    @MainActor
    func test_isSaving_initiallyFalse() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isSaving)
    }

    @MainActor
    func test_saveChanges_persistsEditingModelIfSuccessful() async throws {
        let sut = makeSUT()
        makeDirty(sut: sut)

        await sut.saveChanges()

        XCTAssertFalse(sut.editingModel.isDirty)
    }

    @MainActor
    func test_saveChanges_setsSavingToFalseAfterSaveError() async throws {
        let editor = MockOTPCodeDetailEditor()
        editor.updateCodeResult = .failure(anyNSError())
        let sut = makeSUT(editor: editor)

        await sut.saveChanges()

        XCTAssertFalse(sut.isSaving)
    }

    @MainActor
    func test_saveChanges_doesNotPersistEditingModelIfSaveFailed() async throws {
        let editor = MockOTPCodeDetailEditor()
        editor.updateCodeResult = .failure(anyNSError())
        let sut = makeSUT(editor: editor)
        makeDirty(sut: sut)

        await sut.saveChanges()

        XCTAssertTrue(sut.editingModel.isDirty)
    }

    @MainActor
    func test_saveChanges_sendsErrorIfSaveError() async throws {
        let editor = MockOTPCodeDetailEditor()
        editor.updateCodeResult = .failure(anyNSError())
        let sut = makeSUT(editor: editor)

        let publisher = sut.didEncounterErrorPublisher().collectFirst(1)
        let output = try await awaitPublisher(publisher) {
            await sut.saveChanges()
        }

        XCTAssertEqual(output.count, 1)
    }

    @MainActor
    func test_deleteCode_isSavingSetsBackToFalseAfterSuccessfulDelete() async throws {
        let sut = makeSUT()

        await sut.deleteCode()

        XCTAssertFalse(sut.isSaving)
    }

    @MainActor
    func test_deleteCode_sendsFinishSignalOnSuccessfulDeletion() async throws {
        let sut = makeSUT()

        let publisher = sut.isFinishedPublisher().collectFirst(1)
        let output: [Void] = try await awaitPublisher(publisher) {
            await sut.deleteCode()
        }

        XCTAssertEqual(output.count, 1)
    }

    @MainActor
    func test_deleteCode_sendsErrorIfDeleteError() async throws {
        let editor = MockOTPCodeDetailEditor()
        editor.deleteCodeResult = .failure(anyNSError())
        let sut = makeSUT(editor: editor)

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
        let sut = makeSUT()

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
        let sut = makeSUT(code: code, metadata: metadata)

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
        let sut = makeSUT(code: code, metadata: metadata)

        let editing = sut.editingModel

        XCTAssertEqual(editing.detail.accountNameTitle, "account name test")
        XCTAssertEqual(editing.detail.issuerTitle, "issuer test")
        XCTAssertEqual(editing.detail.description, "description test")
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
    private func makeSUT(
        code: OTPAuthCode = uniqueCode(),
        metadata: StoredVaultItem.Metadata = uniqueStoredMetadata(),
        editor: MockOTPCodeDetailEditor = MockOTPCodeDetailEditor(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OTPCodeDetailViewModel {
        let sut = OTPCodeDetailViewModel(storedCode: code, storedMetadata: metadata, editor: editor)
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
