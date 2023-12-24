import CryptoEngine
import Foundation
import TestHelpers
import XCTest

struct EncryptedVault {
    /// The encrypted payload after encryption.
    let data: Data
    /// Additional data that represents authentication.
    let authentication: Data
}

final class VaultEncryptor {
    private let encryptor: AESGCMEncryptor

    init(key: VaultKey) {
        encryptor = AESGCMEncryptor(key: key.key, iv: key.iv)
    }

    func encrypt(data: Data) throws -> EncryptedVault {
        let encrypted = try encryptor.encrypt(plaintext: data)
        return EncryptedVault(data: encrypted.ciphertext, authentication: encrypted.authenticationTag)
    }
}

final class VaultEncryptorTests: XCTestCase {
    func test_encrypt_emptyDataGivesEmptyEncryption() throws {
        let sut = try makeSUT(key: anyVaultKey())

        let result = try sut.encrypt(data: Data())

        XCTAssertEqual(result.data, Data())
    }

    /// Reference test case: https://gchq.github.io/CyberChef/#recipe=AES_Encrypt(%7B'option':'Hex','string':'3131313131313131313131313131313131313131313131313131313131313131'%7D,%7B'option':'Hex','string':'3232323232323232323232323232323232323232323232323232323232323232'%7D,'GCM','Hex','Hex',%7B'option':'Hex','string':''%7D)&input=NDE0MTQxNDE0MTQxNDE
    func test_encrypt_expectedDataReturnedUsingAESGCM() throws {
        let knownKey = try VaultKey(
            key: Data(repeating: 0x31, count: 32),
            iv: Data(repeating: 0x32, count: 32)
        )
        let sut = makeSUT(key: knownKey)

        let plainData = Data(hex: "0x41414141414141")
        let result = try sut.encrypt(data: plainData)

        XCTAssertEqual(result.data, Data(hex: "0x4126987aceb598"))
        XCTAssertEqual(result.authentication, Data(hex: "0x4343890cb716dfb9915f8f7c050829ca"))
    }
}

// MARK: - Helpers

extension VaultEncryptorTests {
    private func makeSUT(key: VaultKey) -> VaultEncryptor {
        let sut = VaultEncryptor(key: key)
        trackForMemoryLeaks(sut)
        return sut
    }

    private func anyVaultKey() throws -> VaultKey {
        try VaultKey(key: Data(repeating: 0x41, count: 32), iv: Data(repeating: 0x42, count: 32))
    }
}
