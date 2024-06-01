import Foundation
import TestHelpers
import XCTest
@testable import VaultBackup

final class VaultDecryptorTests: XCTestCase {
    func test_decrypt_emptyDataDecryptsToEmpty() throws {
        let sut = try makeSUT(key: anyVaultKey())
        let vault = EncryptedVault(
            data: Data(),
            authentication: Data(),
            encryptionIV: Data(),
            keygenSalt: Data(),
            keygenSignature: .fastV1
        )

        let decrypted = try sut.decrypt(encryptedVault: vault)

        XCTAssertEqual(decrypted.data, Data())
    }

    func test_decrypt_invalidDataFails() throws {
        let sut = try makeSUT(key: anyVaultKey())
        let vault = EncryptedVault(
            data: Data(hex: "0x1234"),
            authentication: Data(hex: "0x1234"),
            encryptionIV: Data(hex: "0x1234"),
            keygenSalt: Data(hex: "0x11"),
            keygenSignature: .fastV1
        )

        XCTAssertThrowsError(try sut.decrypt(encryptedVault: vault))
    }

    /// Reference test case: https://gchq.github.io/CyberChef/#recipe=AES_Encrypt(%7B'option':'Hex','string':'3131313131313131313131313131313131313131313131313131313131313131'%7D,%7B'option':'Hex','string':'3232323232323232323232323232323232323232323232323232323232323232'%7D,'GCM','Hex','Hex',%7B'option':'Hex','string':''%7D)&input=NDE0MTQxNDE0MTQxNDE
    func test_decrypt_expectedDataIsDecrypted() throws {
        let iv = Data(repeating: 0x32, count: 32)
        let key = Data(repeating: 0x31, count: 32)
        let sut = makeSUT(key: key)
        let encryptedData = Data(hex: "0x4126987aceb598")
        let authentication = Data(hex: "0x4343890cb716dfb9915f8f7c050829ca")
        let vault = EncryptedVault(
            data: encryptedData,
            authentication: authentication,
            encryptionIV: iv,
            keygenSalt: Data(),
            keygenSignature: .fastV1
        )

        let decrypted = try sut.decrypt(encryptedVault: vault)

        let plainData = Data(hex: "0x41414141414141")
        XCTAssertEqual(decrypted.data, plainData)
    }
}

// MARK: - Helpers

extension VaultDecryptorTests {
    private func makeSUT(key: Data) -> VaultDecryptor {
        let sut = VaultDecryptor(key: key)
        trackForMemoryLeaks(sut)
        return sut
    }

    private func anyVaultKey() throws -> Data {
        Data(repeating: 0x41, count: 32)
    }
}
