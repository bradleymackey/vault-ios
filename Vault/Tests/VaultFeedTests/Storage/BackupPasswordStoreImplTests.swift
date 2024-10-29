import Foundation
import TestHelpers
import VaultKeygen
import XCTest
@testable import VaultFeed

final class BackupPasswordStoreImplTests: XCTestCase {
    @MainActor
    func test_init_hasNoSecureStorageSideEffects() {
        let storage = SecureStorageMock()
        _ = makeSUT(secureStorage: storage)

        XCTAssertEqual(storage.retrieveCallCount, 0)
        XCTAssertEqual(storage.storeCallCount, 0)
    }

    @MainActor
    func test_fetchPassword_fetchErrorRethrowsError() async throws {
        let storage = SecureStorageMock()
        let sut = makeSUT(secureStorage: storage)
        storage.retrieveHandler = { _ in throw TestError() }

        await XCTAssertThrowsError(try await sut.fetchPassword())
    }

    @MainActor
    func test_fetchPassword_notFoundAnyReturnsNil() async throws {
        let storage = SecureStorageMock()
        let sut = makeSUT(secureStorage: storage)
        storage.retrieveHandler = { _ in nil }

        let password = try await sut.fetchPassword()

        XCTAssertNil(password)
    }

    @MainActor
    func test_setPassword_errorInServiceIsRethrown() async throws {
        let storage = SecureStorageMock()
        let sut = makeSUT(secureStorage: storage)
        storage.storeHandler = { _, _ in
            throw TestError()
        }

        let password = anyBackupPassword()
        await XCTAssertThrowsError(try await sut.set(password: password))
    }

    @MainActor
    func test_setPassword_setsDataEncodedCorrectly() async throws {
        let storage = SecureStorageMock()
        let sut = makeSUT(secureStorage: storage)
        let newPassword = DerivedEncryptionKey(
            key: .random(),
            salt: Data.random(count: 45),
            keyDervier: .fastV1
        )

        try await sut.set(password: newPassword)

        XCTAssertEqual(
            storage.storeArgValues.map(\.1),
            ["vault-backup-password-v1"]
        )
    }
}

// MARK: - Helpers

extension BackupPasswordStoreImplTests {
    @MainActor
    private func makeSUT(
        secureStorage: SecureStorageMock = SecureStorageMock()
    ) -> BackupPasswordStoreImpl {
        BackupPasswordStoreImpl(secureStorage: secureStorage)
    }

    private func anyBackupPassword() -> DerivedEncryptionKey {
        DerivedEncryptionKey(key: .zero(), salt: Data(), keyDervier: .testing)
    }
}
