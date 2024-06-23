import CryptoEngine
import Foundation
import TestHelpers
import VaultCore
import XCTest
@testable import VaultBackup

final class VaultBackupEncoderTests: XCTestCase {
    func test_createExportPayload_encryptedVaultDataIsExpectedVault() throws {
        let key = try VaultKey(key: Data(repeating: 0xAA, count: 32), iv: Data(repeating: 0xAB, count: 32))
        let sut = makeSUT(key: key)

        let encryptedVault = try sut.createExportPayload(items: [], tags: [], userDescription: "hello world")

        // This is the encoded payload created by this test case:

//        {
//          "created" : 1234000,
//          "items" : [
//
//          ],
//          "obfuscation_padding" : "",
//          "tags" : [
//
//          ],
//          "user_description" : "hello world",
//          "version" : "1.0.0"
//        }

        // Manually verified data:
        // https://gchq.github.io/CyberChef/#recipe=AES_Encrypt(%7B'option':'Hex','string':'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'%7D,%7B'option':'Hex','string':'abababababababababababababababababababababababababababababababab'%7D,'GCM','Raw','Hex',%7B'option':'Hex','string':''%7D)&input=ewogICJjcmVhdGVkIiA6IDEyMzQwMDAsCiAgIml0ZW1zIiA6IFsKCiAgXSwKICAib2JmdXNjYXRpb25fcGFkZGluZyIgOiAiIiwKICAidGFncyIgOiBbCgogIF0sCiAgInVzZXJfZGVzY3JpcHRpb24iIDogImhlbGxvIHdvcmxkIiwKICAidmVyc2lvbiIgOiAiMS4wLjAiCn0

        XCTAssertEqual(encryptedVault.data.toHexString(), """
        0050b32570c5c022cfab78cc8b592ea4467e1356fe76dff89c078ff3ace103d3ab72826b177505bada8cb5d66725b3b3ed5887a6ab2f9f6258ce927b13e7e68c3142c6b487141659225347c2a5b21a6ce8d9ec7712b30a415bb60da50c238c6f01c0327737284dcb924be4d41ec8e8a72ac270319a6c845940d3ed6937e3bba6f91c86b07e9c4b9ad657b3eb9185f27726b3ee3a606e11b5ae3593
        """)
        XCTAssertEqual(encryptedVault.authentication.toHexString(), """
        8a90eab22324cbf12366fda7f7006437
        """)
        XCTAssertEqual(encryptedVault.encryptionIV.toHexString(), """
        abababababababababababababababababababababababababababababababab
        """)
    }

    func test_createExportPayload_encryptedVaultDataIsExpectedVaultWithFixedPadding() throws {
        let key = try VaultKey(key: Data(repeating: 0xAA, count: 32), iv: Data(repeating: 0xAB, count: 32))
        let padding = VaultBackupEncoder.PaddingMode.fixed(data: Data(repeating: 0xF1, count: 45))
        let sut = makeSUT(key: key, paddingMode: padding)

        let encryptedVault = try sut.createExportPayload(items: [], tags: [], userDescription: "hello world")

        // This is the encoded payload created by this test case:

//        {
//          "created" : 1234000,
//          "items" : [
//
//          ],
//          "obfuscation_padding" : "8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx",
//          "tags" : [
//
//          ],
//          "user_description" : "hello world",
//          "version" : "1.0.0"
//        }

        // Manually verified data:
        // https://gchq.github.io/CyberChef/#recipe=AES_Encrypt(%7B'option':'Hex','string':'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'%7D,%7B'option':'Hex','string':'abababababababababababababababababababababababababababababababab'%7D,'GCM','Raw','Hex',%7B'option':'Hex','string':''%7D)&input=ewogICJjcmVhdGVkIiA6IDEyMzQwMDAsCiAgIml0ZW1zIiA6IFsKCiAgXSwKICAib2JmdXNjYXRpb25fcGFkZGluZyIgOiAiOGZIeDhmSHg4Zkh4OGZIeDhmSHg4Zkh4OGZIeDhmSHg4Zkh4OGZIeDhmSHg4Zkh4OGZIeDhmSHg4Zkh4IiwKICAidGFncyIgOiBbCgogIF0sCiAgInVzZXJfZGVzY3JpcHRpb24iIDogImhlbGxvIHdvcmxkIiwKICAidmVyc2lvbiIgOiAiMS4wLjAiCn0

        XCTAssertEqual(encryptedVault.data.toHexString(), """
        0050b32570c5c022cfab78cc8b592ea4467e1356fe76dff89c078ff3ace103d3ab72826b177505bada8cb5d66725b3b3ed5887a6ab2f9f6258ce927b13e7e68c3142c6b4871416593819059abdf62675b7cc862f10f5193369f06580184fe4371bd3096a7d1161d6d94edec556dac9b07c8618738228a44414d9ca3178ea81b2a558e2c27c9063cc9307b4e39998f27726b39701447e1fd8a035ced68fdbd0784111e1b61e6576d1329f915ae01d26c13330ec8909c57ca355ac4e97e4a8d9363a9e237a22c3c9823dc69043a1ef6d7dca398856e17f48
        """)
        XCTAssertEqual(encryptedVault.authentication.toHexString(), """
        7867d55c8cad397c71b11c22ea7af7f1
        """)
        XCTAssertEqual(encryptedVault.encryptionIV.toHexString(), """
        abababababababababababababababababababababababababababababababab
        """)
    }

    func test_createExportPayload_includesKeySaltUnmodifiedInPayload() throws {
        let salt = Data.random(count: 34)
        let sut = try makeSUT(key: anyKey(), keygenSalt: salt)

        let encryptedVault = try sut.createExportPayload(items: [], tags: [], userDescription: "hello world")

        XCTAssertEqual(encryptedVault.keygenSalt, salt)
    }
}

// MARK: - Helpers

extension VaultBackupEncoderTests {
    private func makeSUT(
        clock: EpochClock = anyClock(),
        key: VaultKey,
        keygenSalt: Data = Data(),
        keygenSignature: ApplicationKeyDeriver.Signature = .fastV1,
        paddingMode: VaultBackupEncoder.PaddingMode = .none
    ) -> VaultBackupEncoder {
        VaultBackupEncoder(
            clock: clock,
            key: key,
            keygenSalt: keygenSalt,
            keygenSignature: keygenSignature,
            paddingMode: paddingMode
        )
    }
}

private func anyClock() -> EpochClock {
    EpochClock(makeCurrentTime: { 1234 })
}

private func anyKey() throws -> VaultKey {
    try VaultKey(key: Data(repeating: 0x34, count: 32), iv: Data(repeating: 0x35, count: 32))
}
