import Foundation
import PDFKit
import TestHelpers
import VaultBackup
import VaultKeygen
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
    func test_handleImportFromEncryptedVault_validGivesSuccess() async {
        let encryptedVaultDecoder = EncryptedVaultDecoderMock()
        let payload = anyVaultApplicationPayload()
        encryptedVaultDecoder.decryptAndDecodeHandler = { _, _ in
            payload
        }
        let sut = makeSUT(
            existingBackupPassword: anyBackupPassword(),
            encryptedVaultDecoder: encryptedVaultDecoder,
        )

        await sut.handleImport(fromEncryptedVault: anyEncryptedVault())

        switch sut.payloadState {
        case let .ready(readyPayload, _):
            XCTAssertEqual(readyPayload, payload)
        default:
            XCTFail("Invalid state")
        }
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleImportFromEncryptedVault_failedToDecrypt() async throws {
        let encryptedVaultDecoder = EncryptedVaultDecoderMock()
        encryptedVaultDecoder.decryptAndDecodeHandler = { _, _ in
            throw TestError()
        }
        let sut = makeSUT(
            existingBackupPassword: anyBackupPassword(),
            encryptedVaultDecoder: encryptedVaultDecoder,
        )

        await sut.handleImport(fromEncryptedVault: anyEncryptedVault())

        XCTAssertTrue(sut.payloadState.isError)
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleImportFromEncryptedVault_noExistingPasswordPromptsForDifferentPassword() async throws {
        let encryptedVaultDecoder = EncryptedVaultDecoderMock()
        encryptedVaultDecoder.decryptAndDecodeHandler = { _, _ in
            anyVaultApplicationPayload()
        }
        let sut = makeSUT(
            existingBackupPassword: nil,
            encryptedVaultDecoder: encryptedVaultDecoder,
        )
        let encryptedVault = anyEncryptedVault()

        await sut.handleImport(fromEncryptedVault: encryptedVault)

        XCTAssertEqual(sut.payloadState, .needsPasswordEntry(encryptedVault))
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleImportFromEncryptedVault_wrongDecryptionPasswordPromptsForDifferentPassword() async throws {
        let encryptedVaultDecoder = EncryptedVaultDecoderMock()
        encryptedVaultDecoder.decryptAndDecodeHandler = { _, _ in
            throw EncryptedVaultDecoderError.decryption
        }
        let sut = makeSUT(
            existingBackupPassword: anyBackupPassword(),
            encryptedVaultDecoder: encryptedVaultDecoder,
        )
        let encryptedVault = anyEncryptedVault()

        await sut.handleImport(fromEncryptedVault: encryptedVault)

        XCTAssertEqual(sut.payloadState, .needsPasswordEntry(encryptedVault))
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleImportFromPDF_errorUpdatesPresentationError() async {
        let sut = makeSUT()

        await sut.handleImport(fromPDF: .failure(TestError()))

        XCTAssertTrue(sut.payloadState.isError)
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleImportFromPDF_invalidPDFDataFails() async {
        let sut = makeSUT()

        await sut.handleImport(fromPDF: .success(Data()))

        XCTAssertTrue(sut.payloadState.isError)
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleImportFromPDF_validExtractionGivesSuccess() async throws {
        let backupPDFDetatcher = VaultBackupPDFDetatcherMock()
        let encryptedVaultDecoder = EncryptedVaultDecoderMock()
        let payload = anyVaultApplicationPayload()
        encryptedVaultDecoder.decryptAndDecodeHandler = { _, _ in
            payload
        }
        let sut = makeSUT(
            existingBackupPassword: anyBackupPassword(),
            encryptedVaultDecoder: encryptedVaultDecoder,
            backupPDFDetatcher: backupPDFDetatcher,
        )
        backupPDFDetatcher.detachEncryptedVaultHandler = { _ in
            anyEncryptedVault()
        }
        let pdfData = try anyPDFData()

        await sut.handleImport(fromPDF: .success(pdfData))

        switch sut.payloadState {
        case let .ready(readyPayload, _):
            XCTAssertEqual(readyPayload, payload)
        default:
            XCTFail("Invalid state")
        }
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleImportFromPDF_failedToDecrypt() async throws {
        let backupPDFDetatcher = VaultBackupPDFDetatcherMock()
        let encryptedVaultDecoder = EncryptedVaultDecoderMock()
        encryptedVaultDecoder.decryptAndDecodeHandler = { _, _ in
            throw TestError()
        }
        let sut = makeSUT(
            existingBackupPassword: anyBackupPassword(),
            encryptedVaultDecoder: encryptedVaultDecoder,
            backupPDFDetatcher: backupPDFDetatcher,
        )
        backupPDFDetatcher.detachEncryptedVaultHandler = { _ in
            anyEncryptedVault()
        }
        let pdfData = try anyPDFData()

        await sut.handleImport(fromPDF: .success(pdfData))

        XCTAssertTrue(sut.payloadState.isError)
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleImportFromPDF_noExistingPasswordPromptsForDifferentPassword() async throws {
        let backupPDFDetatcher = VaultBackupPDFDetatcherMock()
        let encryptedVaultDecoder = EncryptedVaultDecoderMock()
        encryptedVaultDecoder.decryptAndDecodeHandler = { _, _ in
            anyVaultApplicationPayload()
        }
        let sut = makeSUT(
            existingBackupPassword: nil,
            encryptedVaultDecoder: encryptedVaultDecoder,
            backupPDFDetatcher: backupPDFDetatcher,
        )
        let encryptedVault = anyEncryptedVault()
        backupPDFDetatcher.detachEncryptedVaultHandler = { _ in
            encryptedVault
        }
        let pdfData = try anyPDFData()

        await sut.handleImport(fromPDF: .success(pdfData))

        XCTAssertEqual(sut.payloadState, .needsPasswordEntry(encryptedVault))
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleImportFromPDF_wrongDecryptionPasswordPromptsForDifferentPassword() async throws {
        let backupPDFDetatcher = VaultBackupPDFDetatcherMock()
        let encryptedVaultDecoder = EncryptedVaultDecoderMock()
        encryptedVaultDecoder.decryptAndDecodeHandler = { _, _ in
            throw EncryptedVaultDecoderError.decryption
        }
        let sut = makeSUT(
            existingBackupPassword: anyBackupPassword(),
            encryptedVaultDecoder: encryptedVaultDecoder,
            backupPDFDetatcher: backupPDFDetatcher,
        )
        let encryptedVault = anyEncryptedVault()
        backupPDFDetatcher.detachEncryptedVaultHandler = { _ in
            encryptedVault
        }
        let pdfData = try anyPDFData()

        await sut.handleImport(fromPDF: .success(pdfData))

        XCTAssertEqual(sut.payloadState, .needsPasswordEntry(encryptedVault))
        XCTAssertEqual(sut.importState, .notStarted)
    }

    @MainActor
    func test_handleVaultDecoded_updatesPayloadStateToReady() {
        let sut = makeSUT()

        let initialPayload = anyVaultApplicationPayload()
        sut.handleVaultDecoded(payload: initialPayload)

        switch sut.payloadState {
        case let .ready(payload, _):
            XCTAssertEqual(payload, initialPayload)
        default:
            XCTFail("Invalid")
        }
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
            vaultKillphraseDeleter: VaultStoreKillphraseDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock(),
        ),
        existingBackupPassword: DerivedEncryptionKey? = nil,
        encryptedVaultDecoder: EncryptedVaultDecoderMock = EncryptedVaultDecoderMock(),
        backupPDFDetatcher: VaultBackupPDFDetatcherMock = VaultBackupPDFDetatcherMock(),
    ) -> BackupImportFlowViewModel {
        BackupImportFlowViewModel(
            importContext: importContext,
            dataModel: dataModel,
            existingBackupPassword: existingBackupPassword,
            encryptedVaultDecoder: encryptedVaultDecoder,
            backupPDFDetatcher: backupPDFDetatcher,
        )
    }
}
