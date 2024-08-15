import CryptoEngine
import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class BackupKeyImportViewModelTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let store = BackupPasswordStoreMock()
        _ = makeSUT(store: store)

        XCTAssertEqual(store.fetchPasswordCallCount, 0)
        XCTAssertEqual(store.setCallCount, 0)
    }

    @MainActor
    func test_init_initialImportStateIsWaiting() {
        let sut = makeSUT()

        XCTAssertEqual(sut.importState, .waiting)
    }

    @MainActor
    func test_commitStagedImport_noActionIfNothingStagedd() {
        let store = BackupPasswordStoreMock()
        let sut = makeSUT(store: store)

        sut.commitStagedImport()

        XCTAssertEqual(store.setArgValues, [])
        XCTAssertEqual(sut.importState, .waiting)
    }

    @MainActor
    func test_commitStagedImport_importsAndUpdatesState() async {
        let importData = Data(repeating: 0x44, count: 13)
        let store = BackupPasswordStoreMock()
        let sut = makeSUT(store: store)
        let password = BackupPassword(key: importData, salt: importData, keyDervier: .testing)

        await sut.stageImport(password: password)
        sut.commitStagedImport()

        XCTAssertEqual(store.setArgValues, [password])
        XCTAssertEqual(sut.importState, .imported)
    }

    @MainActor
    func test_importPassword_setsStateToErrorIfOperationFails() async {
        let store = BackupPasswordStoreMock()
        store.setHandler = { _ in
            throw anyNSError()
        }
        let sut = makeSUT(store: store)

        await sut.stageImport(password: .init(key: Data(), salt: Data(), keyDervier: .testing))
        sut.commitStagedImport()

        XCTAssertEqual(store.setCallCount, 1)
        XCTAssertEqual(sut.importState, .error)
    }
}

// MARK: - Helpers

extension BackupKeyImportViewModelTests {
    @MainActor
    private func makeSUT(
        store: BackupPasswordStoreMock = BackupPasswordStoreMock()
    ) -> BackupKeyImportViewModel {
        BackupKeyImportViewModel(dataModel: anyVaultDataModel(backupPasswordStore: store))
    }
}
