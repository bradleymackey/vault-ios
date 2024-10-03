import Foundation
import TestHelpers
import Testing
@testable import VaultBackup

struct VaultDecryptorTests {
    @Test
    func decrypt_emptyDataDecryptsToEmpty() throws {
        let sut = try makeSUT(key: anyVaultKey())
        let vault = EncryptedVault(
            data: Data(),
            authentication: Data(),
            encryptionIV: Data(),
            keygenSalt: Data(),
            keygenSignature: "signature"
        )

        let decrypted = try sut.decrypt(encryptedVault: vault)

        #expect(decrypted.data == Data())
    }

    @Test
    func decrypt_invalidDataFails() throws {
        let sut = try makeSUT(key: anyVaultKey())
        let vault = EncryptedVault(
            data: Data(hex: "0x1234"),
            authentication: Data(hex: "0x1234"),
            encryptionIV: Data(hex: "0x1234"),
            keygenSalt: Data(hex: "0x11"),
            keygenSignature: "signature"
        )

        #expect(throws: (any Error).self, performing: {
            try sut.decrypt(encryptedVault: vault)
        })
    }

    /// Reference test case: https://gchq.github.io/CyberChef/#recipe=AES_Encrypt(%7B'option':'Hex','string':'3131313131313131313131313131313131313131313131313131313131313131'%7D,%7B'option':'Hex','string':'3232323232323232323232323232323232323232323232323232323232323232'%7D,'GCM','Hex','Hex',%7B'option':'Hex','string':''%7D)&input=NDE0MTQxNDE0MTQxNDE
    @Test
    func decrypt_expectedDataIsDecrypted() throws {
        let iv = Data(repeating: 0x32, count: 32)
        let key = Data(repeating: 0x31, count: 32)
        let sut = try makeSUT(key: key)
        let encryptedData = Data(hex: "0x4126987aceb598")
        let authentication = Data(hex: "0x4343890cb716dfb9915f8f7c050829ca")
        let vault = EncryptedVault(
            data: encryptedData,
            authentication: authentication,
            encryptionIV: iv,
            keygenSalt: Data(),
            keygenSignature: "signature"
        )

        let decrypted = try sut.decrypt(encryptedVault: vault)

        let plainData = Data(hex: "0x41414141414141")
        #expect(decrypted.data == plainData)
    }
}

// MARK: - Helpers

extension VaultDecryptorTests {
    private func makeSUT(key: Data) throws -> VaultDecryptor {
        let sut = try VaultDecryptor(key: .init(data: key))
        return sut
    }

    private func anyVaultKey() throws -> Data {
        Data(repeating: 0x41, count: 32)
    }
}
