import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class BackupKeyChangeViewModelTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let store = BackupPasswordStoreMock()
        _ = makeSUT(store: store)

        XCTAssertEqual(store.passwordSetCallCount, 0)
    }

    @MainActor
    func test_init_existingPasswordInitialStateIsLoading() {
        let sut = makeSUT()

        XCTAssertEqual(sut.existingPassword, .loading)
    }

    @MainActor
    func test_loadInitialData_loadsKeyIfItExists() {
        let store = BackupPasswordStoreMock()
        let password = randomBackupPassword()
        store.password = password
        let sut = makeSUT(store: store)

        sut.loadInitialData()

        XCTAssertEqual(sut.existingPassword, .hasExistingPassword(password))
    }

    @MainActor
    func test_loadInitialData_doesNotLoadKeyIfItDoesNotExist() {
        let store = BackupPasswordStoreMock()
        store.password = nil
        let sut = makeSUT(store: store)

        sut.loadInitialData()

        XCTAssertEqual(sut.existingPassword, .noExistingPassword)
    }
}

// MARK: - Helpers

extension BackupKeyChangeViewModelTests {
    @MainActor
    private func makeSUT(
        store: BackupPasswordStoreMock = BackupPasswordStoreMock()
    ) -> BackupKeyChangeViewModel {
        BackupKeyChangeViewModel(store: store)
    }

    private func anyBackupPassword() -> BackupPassword {
        BackupPassword(key: Data(repeating: 0x45, count: 10), salt: Data())
    }

    private func randomBackupPassword() -> BackupPassword {
        BackupPassword(key: Data.random(count: 10), salt: Data())
    }
}
