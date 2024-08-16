import CryptoEngine
import Foundation
import TestHelpers
import XCTest
@testable import VaultBackup

final class VaultEncryptorTests: XCTestCase {
    @MainActor
    func test_encrypt_emptyDataGivesEmptyEncryption() throws {
        let sut = makeSUT(key: anyVaultKey())
        let encodedVault = IntermediateEncodedVault(data: Data())

        let result = try sut.encrypt(encodedVault: encodedVault)

        XCTAssertEqual(result.data, Data())
    }

    /// Reference test case: https://gchq.github.io/CyberChef/#recipe=AES_Encrypt(%7B'option':'Hex','string':'3131313131313131313131313131313131313131313131313131313131313131'%7D,%7B'option':'Hex','string':'3232323232323232323232323232323232323232323232323232323232323232'%7D,'GCM','Hex','Hex',%7B'option':'Hex','string':''%7D)&input=NDE0MTQxNDE0MTQxNDE
    @MainActor
    func test_encrypt_expectedDataReturnedUsingAESGCM() throws {
        let knownKey = VaultKey(
            key: .repeating(byte: 0x31),
            iv: .repeating(byte: 0x32)
        )
        let sut = makeSUT(key: knownKey)
        let plainData = Data(hex: "0x41414141414141")
        let encodedVault = IntermediateEncodedVault(data: plainData)

        let result = try sut.encrypt(encodedVault: encodedVault)

        XCTAssertEqual(result.data, Data(hex: "0x4126987aceb598"))
        XCTAssertEqual(result.authentication, Data(hex: "0x4343890cb716dfb9915f8f7c050829ca"))
    }

    @MainActor
    func test_encrypt_placesKeygenSaltIntoPayloadUnchanged() throws {
        let plainData = Data(hex: "0x41414141414141")
        let encodedVault = IntermediateEncodedVault(data: plainData)
        let keygenSalt = Data.random(count: 30)
        let sut = makeSUT(key: anyVaultKey(), keygenSalt: keygenSalt)

        let result = try sut.encrypt(encodedVault: encodedVault)

        XCTAssertEqual(result.keygenSalt, keygenSalt)
    }

    @MainActor
    func test_encrypt_placesKeygenSignatureIntoPayloadUnchanged() throws {
        let plainData = Data(hex: "0x41414141414141")
        let encodedVault = IntermediateEncodedVault(data: plainData)
        let sut = makeSUT(key: anyVaultKey(), keygenSignature: .secureV1)

        let result = try sut.encrypt(encodedVault: encodedVault)

        XCTAssertEqual(result.keygenSignature, .secureV1)
    }
}

// MARK: - Helpers

extension VaultEncryptorTests {
    @MainActor
    private func makeSUT(
        key: VaultKey,
        keygenSalt: Data = Data(),
        keygenSignature: ApplicationKeyDeriver.Signature = .fastV1
    ) -> VaultEncryptor {
        let sut = VaultEncryptor(key: key, keygenSalt: keygenSalt, keygenSignature: keygenSignature)
        trackForMemoryLeaks(sut)
        return sut
    }

    private func anyVaultKey() -> VaultKey {
        VaultKey(key: .repeating(byte: 0x41), iv: .repeating(byte: 0x42))
    }
}
