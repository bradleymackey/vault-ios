import Foundation
import TestHelpers
import XCTest

/// A key used to encrypt or decrypt a vault.
struct VaultKey {
    /// The key data for a vault.
    let key: Data
    /// Initialization vector.
    let iv: Data
}

struct EncryptedVault {
    /// The encrypted payload after encryption.
    let data: Data
    /// Additional data that represents authentication.
    let authentication: Data
}

final class VaultEncryptor {
    private let key: VaultKey

    init(key: VaultKey) {
        self.key = key
    }

    func encrypt(data: Data) throws -> EncryptedVault {
        EncryptedVault(data: data, authentication: data)
    }
}

final class VaultEncryptorTests: XCTestCase {
    func test_encrypt_emptyDataGivesEmptyEncryption() throws {
        let sut = makeSUT(key: anyVaultKey())

        let result = try sut.encrypt(data: Data())

        XCTAssertEqual(result.data, Data())
    }
}

// MARK: - Helpers

extension VaultEncryptorTests {
    private func makeSUT(key: VaultKey) -> VaultEncryptor {
        let sut = VaultEncryptor(key: key)
        trackForMemoryLeaks(sut)
        return sut
    }

    private func anyVaultKey() -> VaultKey {
        VaultKey(key: Data(), iv: Data())
    }
}
