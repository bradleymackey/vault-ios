import Foundation
import TestHelpers
import VaultBackup
import XCTest
@testable import VaultFeed

final class EncryptedVaultDecoderTests: XCTestCase {
    func test_verifyCanDecrypt_successIfDecryptionSuccess() throws {
        let password = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptedBackup = try makeEncryptedVault(password: password, description: "my backup", items: [], tags: [])
        let sut = makeSUT()

        try sut.verifyCanDecrypt(key: password.key, encryptedVault: encryptedBackup)
    }

    func test_verifyCanDecrypt_throwsDecryptionErrorIfFailed() throws {
        let password = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptedBackup = try makeEncryptedVault(password: password, description: "my backup", items: [], tags: [])
        let sut = makeSUT()

        let error: EncryptedVaultDecoderError? = try withCatchingSomeError {
            try sut.verifyCanDecrypt(key: .random(), encryptedVault: encryptedBackup)
        }
        XCTAssertEqual(error, .decryption)
    }

    func test_decryptAndDecode_decodesWithNoItems() throws {
        let password = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptedBackup = try makeEncryptedVault(password: password, description: "my backup", items: [], tags: [])
        let sut = makeSUT()

        let decoded = try sut.decryptAndDecode(key: password.key, encryptedVault: encryptedBackup)

        XCTAssertEqual(decoded.items, [])
        XCTAssertEqual(decoded.tags, [])
        XCTAssertEqual(decoded.userDescription, "my backup")
    }

    func test_decryptAndDecode_decodesWithItems() throws {
        let item1 = uniqueVaultItem()
        let tag1 = VaultItemTag(id: .init(id: UUID()), name: "tag1")
        let tag2 = VaultItemTag(id: .init(id: UUID()), name: "tag2")
        let password = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptedBackup = try makeEncryptedVault(
            password: password,
            description: "my backup description",
            items: [item1],
            tags: [tag1, tag2]
        )
        let sut = makeSUT()

        let decoded = try sut.decryptAndDecode(key: password.key, encryptedVault: encryptedBackup)

        XCTAssertEqual(decoded.items.map(\.id), [item1].map(\.id))
        XCTAssertEqual(decoded.tags, [tag1, tag2])
        XCTAssertEqual(decoded.userDescription, "my backup description")
    }

    func test_decryptAndDecode_throwsDecryptionErrorIfFailed() throws {
        let password = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptedBackup = try makeEncryptedVault(password: password, description: "my backup", items: [], tags: [])
        let sut = makeSUT()

        let error: EncryptedVaultDecoderError? = try withCatchingSomeError {
            _ = try sut.decryptAndDecode(key: .random(), encryptedVault: encryptedBackup)
        }
        XCTAssertEqual(error, .decryption)
    }
}

// MARK: - Helpers

extension EncryptedVaultDecoderTests {
    private func makeSUT() -> EncryptedVaultDecoderImpl {
        EncryptedVaultDecoderImpl()
    }

    private func makeEncryptedVault(
        password: DerivedEncryptionKey,
        description: String = "any",
        items: [VaultItem] = [],
        tags: [VaultItemTag] = []
    ) throws -> EncryptedVault {
        let encoder = EncryptedVaultEncoder(clock: EpochClockMock(currentTime: 100), backupPassword: password)
        let payload = VaultApplicationPayload(userDescription: description, items: items, tags: tags)
        return try encoder.encryptAndEncode(payload: payload)
    }
}
