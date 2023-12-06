import Foundation
import TestHelpers
import XCTest

struct VaultKey {
    /// The key data for a vault.
    let key: Data
    /// Initialization vector.
    let iv: Data
}

final class VaultEncryptor {
    private let key: VaultKey

    init(key: VaultKey) {
        self.key = key
    }

    func encrypt(data: Data) throws -> Data {
        data
    }
}

final class VaultEncryptorTests: XCTestCase {
    func test_encrypt_emptyDataStaysEmpty() throws {
        let sut = makeSUT(key: anyVaultKey())

        let result = try sut.encrypt(data: Data())

        XCTAssertEqual(result, Data())
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
