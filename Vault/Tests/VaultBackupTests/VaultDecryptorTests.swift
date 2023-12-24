import CryptoEngine
import Foundation
import TestHelpers
import VaultBackup
import XCTest

final class VaultDecryptor {
    private let decryptor: AESGCMDecryptor
    init(key: VaultKey) {
        decryptor = AESGCMDecryptor(key: key.key, iv: key.iv)
    }

    public func decrypt(encryptedVault: EncryptedVault) throws -> EncodedVault {
        let decrypted = try decryptor.decrypt(
            message: .init(ciphertext: encryptedVault.data, authenticationTag: encryptedVault.authentication)
        )
        return EncodedVault(data: decrypted)
    }
}

final class VaultDecryptorTests: XCTestCase {
    func test_decrypt_emptyDataDecryptsToEmpty() throws {
        let sut = try makeSUT(key: anyVaultKey())
        let vault = EncryptedVault(data: Data(), authentication: Data())

        let decrypted = try sut.decrypt(encryptedVault: vault)

        XCTAssertEqual(decrypted.data, Data())
    }

    /// Reference test case: https://gchq.github.io/CyberChef/#recipe=AES_Encrypt(%7B'option':'Hex','string':'3131313131313131313131313131313131313131313131313131313131313131'%7D,%7B'option':'Hex','string':'3232323232323232323232323232323232323232323232323232323232323232'%7D,'GCM','Hex','Hex',%7B'option':'Hex','string':''%7D)&input=NDE0MTQxNDE0MTQxNDE
    func test_decrypt_expectedDataIsDecrypted() throws {
        let knownKey = try VaultKey(
            key: Data(repeating: 0x31, count: 32),
            iv: Data(repeating: 0x32, count: 32)
        )
        let sut = makeSUT(key: knownKey)
        let encryptedData = Data(hex: "0x4126987aceb598")
        let authentication = Data(hex: "0x4343890cb716dfb9915f8f7c050829ca")
        let vault = EncryptedVault(data: encryptedData, authentication: authentication)

        let decrypted = try sut.decrypt(encryptedVault: vault)

        let plainData = Data(hex: "0x41414141414141")
        XCTAssertEqual(decrypted.data, plainData)
    }
}

// MARK: - Helpers

extension VaultDecryptorTests {
    private func makeSUT(key: VaultKey) -> VaultDecryptor {
        let sut = VaultDecryptor(key: key)
        trackForMemoryLeaks(sut)
        return sut
    }

    private func anyVaultKey() throws -> VaultKey {
        try VaultKey(key: Data(repeating: 0x41, count: 32), iv: Data(repeating: 0x42, count: 32))
    }
}
