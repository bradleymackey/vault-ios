import CryptoEngine
import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class BackupKeyImportViewModelTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let importer = BackupPasswordImporterMock()
        _ = makeSUT(importer: importer)

        XCTAssertEqual(importer.importAndOverridePasswordCallCount, 0)
    }

    @MainActor
    func test_init_initialImportStateIsWaiting() {
        let sut = makeSUT()

        XCTAssertEqual(sut.importState, .waiting)
    }

    @MainActor
    func test_importPassword_importsAndUpdatesState() {
        let importData = Data(repeating: 0x44, count: 13)
        let importer = BackupPasswordImporterMock()
        let sut = makeSUT(importer: importer)

        sut.importPassword(data: importData)

        XCTAssertEqual(importer.importAndOverridePasswordArgValues, [importData])
        XCTAssertEqual(sut.importState, .imported)
    }

    @MainActor
    func test_importPassword_setsStateToErrorIfOperationFails() {
        let importer = BackupPasswordImporterMock()
        importer.importAndOverridePasswordHandler = { _ in
            throw anyNSError()
        }
        let sut = makeSUT(importer: importer)

        sut.importPassword(data: Data())

        XCTAssertEqual(importer.importAndOverridePasswordCallCount, 1)
        XCTAssertEqual(sut.importState, .error)
    }
}

// MARK: - Helpers

extension BackupKeyImportViewModelTests {
    @MainActor
    private func makeSUT(
        importer: BackupPasswordImporterMock = BackupPasswordImporterMock()
    ) -> BackupKeyImportViewModel {
        BackupKeyImportViewModel(importer: importer)
    }
}
