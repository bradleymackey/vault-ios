import Foundation
import PDFKit
import TestHelpers
import VaultBackup
import XCTest
@testable import VaultFeed

final class BackupImportFlowViewModelTests: XCTestCase {
    @MainActor
    func test_init_initialState() {
        let sut = makeSUT()

        XCTAssertEqual(sut.payloadState, .none)
        XCTAssertEqual(sut.importState, .notStarted)
        XCTAssertFalse(sut.isImporting)
    }

    @MainActor
    func test_handleImport_errorUpdatesPresentationError() async {
        let sut = makeSUT()

        await sut.handleImport(result: .failure(TestError()))

        XCTAssertTrue(sut.payloadState.isError)
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleImport_invalidPDFDataFails() async {
        let sut = makeSUT()

        await sut.handleImport(result: .success(Data()))

        XCTAssertTrue(sut.payloadState.isError)
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleImport_validExtractionGivesSuccess() async throws {
        let backupPDFDetatcher = VaultBackupPDFDetatcherMock()
        let encryptedVaultDecoder = EncryptedVaultDecoderMock()
        let payload = anyVaultApplicationPayload()
        encryptedVaultDecoder.decryptAndDecodeHandler = { _, _ in
            payload
        }
        let sut = makeSUT(
            existingBackupPassword: anyBackupPassword(),
            encryptedVaultDecoder: encryptedVaultDecoder,
            backupPDFDetatcher: backupPDFDetatcher
        )
        backupPDFDetatcher.detachEncryptedVaultHandler = { _ in
            anyEncryptedVault()
        }
        let pdfData = try anyPDFData()

        await sut.handleImport(result: .success(pdfData))

        switch sut.payloadState {
        case let .ready(readyPayload, _):
            XCTAssertEqual(readyPayload, payload)
        default:
            XCTFail("Invalid state")
        }
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleImport_failedToDecrypt() async throws {
        let backupPDFDetatcher = VaultBackupPDFDetatcherMock()
        let encryptedVaultDecoder = EncryptedVaultDecoderMock()
        encryptedVaultDecoder.decryptAndDecodeHandler = { _, _ in
            throw TestError()
        }
        let sut = makeSUT(
            existingBackupPassword: anyBackupPassword(),
            encryptedVaultDecoder: encryptedVaultDecoder,
            backupPDFDetatcher: backupPDFDetatcher
        )
        backupPDFDetatcher.detachEncryptedVaultHandler = { _ in
            anyEncryptedVault()
        }
        let pdfData = try anyPDFData()

        await sut.handleImport(result: .success(pdfData))

        XCTAssertTrue(sut.payloadState.isError)
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_importPayload_toEmptyVault() async throws {
        let importer = VaultStoreImporterMock()
        let dataModel = anyVaultDataModel(vaultImporter: importer)
        let sut = makeSUT(importContext: .toEmptyVault, dataModel: dataModel)

        await sut.importPayload(payload: anyVaultApplicationPayload())

        XCTAssertEqual(sut.importState, .success)
        XCTAssertEqual(importer.importAndMergeVaultCallCount, 1)
        XCTAssertEqual(importer.importAndOverrideVaultCallCount, 0)
    }

    @MainActor
    func test_importPayload_merge() async throws {
        let importer = VaultStoreImporterMock()
        let dataModel = anyVaultDataModel(vaultImporter: importer)
        let sut = makeSUT(importContext: .merge, dataModel: dataModel)

        await sut.importPayload(payload: anyVaultApplicationPayload())

        XCTAssertEqual(sut.importState, .success)
        XCTAssertEqual(importer.importAndMergeVaultCallCount, 1)
        XCTAssertEqual(importer.importAndOverrideVaultCallCount, 0)
    }

    @MainActor
    func test_importPayload_override() async throws {
        let importer = VaultStoreImporterMock()
        let dataModel = anyVaultDataModel(vaultImporter: importer)
        let sut = makeSUT(importContext: .override, dataModel: dataModel)

        await sut.importPayload(payload: anyVaultApplicationPayload())

        XCTAssertEqual(sut.importState, .success)
        XCTAssertEqual(importer.importAndMergeVaultCallCount, 0)
        XCTAssertEqual(importer.importAndOverrideVaultCallCount, 1)
    }
}

// MARK: - Helpers

extension BackupImportFlowViewModelTests {
    @MainActor
    private func makeSUT(
        importContext: BackupImportContext = .toEmptyVault,
        dataModel: VaultDataModel = VaultDataModel(
            vaultStore: VaultStoreStub(),
            vaultTagStore: VaultTagStoreStub(),
            vaultImporter: VaultStoreImporterMock(),
            vaultDeleter: VaultStoreDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock()
        ),
        existingBackupPassword: BackupPassword? = nil,
        encryptedVaultDecoder: EncryptedVaultDecoderMock = EncryptedVaultDecoderMock(),
        backupPDFDetatcher: VaultBackupPDFDetatcherMock = VaultBackupPDFDetatcherMock()
    ) -> BackupImportFlowViewModel {
        BackupImportFlowViewModel(
            importContext: importContext,
            dataModel: dataModel,
            existingBackupPassword: existingBackupPassword,
            encryptedVaultDecoder: encryptedVaultDecoder,
            backupPDFDetatcher: backupPDFDetatcher
        )
    }
}
