import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class BackupPasswordStoreImplTests: XCTestCase {
    func test_init_hasNoSecureStorageSideEffects() {
        let storage = SecureStorageMock()
        _ = makeSUT(secureStorage: storage)

        XCTAssertEqual(storage.retrieveCallCount, 0)
        XCTAssertEqual(storage.storeCallCount, 0)
    }

    func test_fetchPassword_fetchErrorRethrowsError() throws {
        let storage = SecureStorageMock()
        let sut = makeSUT(secureStorage: storage)
        storage.retrieveHandler = { _ in throw anyNSError() }

        XCTAssertThrowsError(try sut.fetchPassword())
    }

    func test_fetchPassword_notFoundAnyReturnsNil() throws {
        let storage = SecureStorageMock()
        let sut = makeSUT(secureStorage: storage)
        storage.retrieveHandler = { _ in nil }

        let password = try sut.fetchPassword()

        XCTAssertNil(password)
    }

    func test_setPassword_errorInServiceIsRethrown() throws {
        let storage = SecureStorageMock()
        let sut = makeSUT(secureStorage: storage)
        storage.storeHandler = { _, _ in
            throw anyNSError()
        }

        XCTAssertThrowsError(try sut.set(password: anyBackupPassword()))
    }

    func test_setPassword_setsDataEncodedCorrectly() throws {
        let storage = SecureStorageMock()
        let sut = makeSUT(secureStorage: storage)
        let newPassword = BackupPassword(
            key: Data.random(count: 32),
            salt: Data.random(count: 45),
            keyDervier: .fastV1
        )

        try sut.set(password: newPassword)

        XCTAssertEqual(
            storage.storeArgValues.map(\.1),
            ["vault-backup-password-v1"]
        )
    }
}

// MARK: - Helpers

extension BackupPasswordStoreImplTests {
    private func makeSUT(
        secureStorage: SecureStorageMock = SecureStorageMock()
    ) -> BackupPasswordStoreImpl {
        BackupPasswordStoreImpl(secureStorage: secureStorage)
    }

    private func anyBackupPassword() -> BackupPassword {
        BackupPassword(key: Data(), salt: Data(), keyDervier: .testing)
    }
}
