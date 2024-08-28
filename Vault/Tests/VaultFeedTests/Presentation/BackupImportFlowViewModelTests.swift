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

        XCTAssertEqual(sut.state, .idle)
        XCTAssertFalse(sut.state.isError)
    }

    @MainActor
    func test_handleImport_errorUpdatesPresentationError() async {
        let sut = makeSUT()

        await sut.handleImport(result: .failure(TestError()))

        XCTAssertTrue(sut.state.isError)
    }

    @MainActor
    func test_handleImport_noDataFails() async {
        let sut = makeSUT()

        await sut.handleImport(result: .success(Data()))

        XCTAssertTrue(sut.state.isError)
    }

//    @MainActor
//    func test_handleImport_validExtractionGivesSuccess() async throws {
//        let backupPDFDetatcher = VaultBackupPDFDetatcherMock()
//        let sut = makeSUT(existingBackupPassword: anyBackupPassword(), backupPDFDetatcher: backupPDFDetatcher)
//        backupPDFDetatcher.detachEncryptedVaultHandler = { _ in
//            anyEncryptedVault()
//        }
//
//        let path = randomTmpPath()
//        let pdf = PDFDocument()
//        pdf.write(to: path)
//
//        let data = try Data(contentsOf: path)
//
//        await sut.handleImport(result: .success(data))
//
//        XCTAssertEqual(sut.state, .success)
//    }
}

// MARK: - Helpers

extension BackupImportFlowViewModelTests {
    @MainActor
    private func makeSUT(
        importContext: BackupImportFlowViewModel.ImportContext = .toEmptyVault,
        existingBackupPassword: BackupPassword? = nil,
        backupPDFDetatcher: VaultBackupPDFDetatcherMock = VaultBackupPDFDetatcherMock()
    ) -> BackupImportFlowViewModel {
        BackupImportFlowViewModel(
            importContext: importContext,
            dataModel: anyVaultDataModel(),
            existingBackupPassword: existingBackupPassword,
            backupPDFDetatcher: backupPDFDetatcher
        )
    }

    private func randomTmpPath() -> URL {
        FileManager().temporaryDirectory.appending(path: UUID().uuidString)
    }
}

private func anyEncryptedVault() -> EncryptedVault {
    EncryptedVault(
        data: Data(),
        authentication: Data(),
        encryptionIV: Data(),
        keygenSalt: Data(),
        keygenSignature: "my-signature"
    )
}
