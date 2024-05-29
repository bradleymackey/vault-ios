import Foundation
import TestHelpers
import VaultCore
import XCTest
@testable import VaultBackup

final class VaultBackupEncoderTests: XCTestCase {
    func test_createExportPayload_encryptedVaultDataIsExpectedVault() throws {
        let key = try VaultKey(key: Data(repeating: 0xAA, count: 32), iv: Data(repeating: 0xAB, count: 32))
        let sut = makeSUT(key: key)

        let encryptedVault = try sut.createExportPayload(items: [], userDescription: "hello world")

        // This is the encoded payload created by this test case:

//        {
//          "created" : 1234000,
//          "items" : [
//
//          ],
//          "obfuscation_padding" : "",
//          "user_description" : "hello world",
//          "version" : "1.0.0"
//        }

        // Manually verified data:
        // https://gchq.github.io/CyberChef/#recipe=AES_Encrypt(%7B'option':'Hex','string':'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'%7D,%7B'option':'Hex','string':'abababababababababababababababababababababababababababababababab'%7D,'GCM','Raw','Hex',%7B'option':'Hex','string':''%7D)&input=ewogICJjcmVhdGVkIiA6IDEyMzQwMDAsCiAgIml0ZW1zIiA6IFsKCiAgXSwKICAib2JmdXNjYXRpb25fcGFkZGluZyIgOiAiIiwKICAidXNlcl9kZXNjcmlwdGlvbiIgOiAiaGVsbG8gd29ybGQiLAogICJ2ZXJzaW9uIiA6ICIxLjAuMCIKfQ

        XCTAssertEqual(encryptedVault.data.toHexString(), """
        0050b32570c5c022cfab78cc8b592ea4467e1356fe76dff89c078ff3ace10\
        3d3ab72826b177505bada8cb5d66725b3b3ed5887a6ab2f9f6258ce927b13\
        e7e68c3142c6b487141659225347c2a5b21b7eead891334de0323938e6599\
        14f478e6f1995637a201b45c1c15ff9cf02d8a3e44ec07029cc2b9e4f45d0\
        ec6b60b6e9e8ac109a946e9e6391
        """)
        XCTAssertEqual(encryptedVault.authentication.toHexString(), """
        837b99a7c9d7e7b4cb56fe2f863d6034
        """)
        XCTAssertEqual(encryptedVault.encryptionIV.toHexString(), """
        abababababababababababababababababababababababababababababababab
        """)
    }

    func test_createExportPayload_encryptedVaultDataIsExpectedVaultWithFixedPadding() throws {
        let key = try VaultKey(key: Data(repeating: 0xAA, count: 32), iv: Data(repeating: 0xAB, count: 32))
        let padding = VaultBackupEncoder.PaddingMode.fixed(data: Data(repeating: 0xF1, count: 45))
        let sut = makeSUT(key: key, paddingMode: padding)

        let encryptedVault = try sut.createExportPayload(items: [], userDescription: "hello world")

        // This is the encoded payload created by this test case:

//        {
//          "created" : 1234000,
//          "items" : [
//
//          ],
//          "obfuscation_padding" : "8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx",
//          "user_description" : "hello world",
//          "version" : "1.0.0"
//        }

        // Manually verified data:
        // https://gchq.github.io/CyberChef/#recipe=AES_Encrypt(%7B'option':'Hex','string':'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'%7D,%7B'option':'Hex','string':'abababababababababababababababababababababababababababababababab'%7D,'GCM','Raw','Hex',%7B'option':'Hex','string':''%7D)&input=ewogICJjcmVhdGVkIiA6IDEyMzQwMDAsCiAgIml0ZW1zIiA6IFsKCiAgXSwKICAib2JmdXNjYXRpb25fcGFkZGluZyIgOiAiOGZIeDhmSHg4Zkh4OGZIeDhmSHg4Zkh4OGZIeDhmSHg4Zkh4OGZIeDhmSHg4Zkh4OGZIeDhmSHg4Zkh4IiwKICAidXNlcl9kZXNjcmlwdGlvbiIgOiAiaGVsbG8gd29ybGQiLAogICJ2ZXJzaW9uIiA6ICIxLjAuMCIKfQ

        XCTAssertEqual(encryptedVault.data.toHexString(), """
        0050b32570c5c022cfab78cc8b592ea4467e1356fe76dff89c078ff3ace10\
        3d3ab72826b177505bada8cb5d66725b3b3ed5887a6ab2f9f6258ce927b13\
        e7e68c3142c6b4871416593819059abdf62675b7cc862f10f5193369f0658\
        0184fe4371bd3096a7d1161d6d94edec556dac9b07c8618738228a44414d9\
        ca3178ea81b2a558e2c27c9063cc9307b5f19b998f3379e0af79272e4bece\
        351ccd6978e81755622e9bc4d716bca2e8fda19841f26d96577f69f0cc67d\
        a102f91cd9b1a4c5122a9c0b71
        """)
        XCTAssertEqual(encryptedVault.authentication.toHexString(), """
        f13dfab30d7ab1b70c5925d83064d5fb
        """)
        XCTAssertEqual(encryptedVault.encryptionIV.toHexString(), """
        abababababababababababababababababababababababababababababababab
        """)
    }
}

// MARK: - Helpers

extension VaultBackupEncoderTests {
    private func makeSUT(
        clock: EpochClock = anyClock(),
        key: VaultKey,
        paddingMode: VaultBackupEncoder.PaddingMode = .none
    ) -> VaultBackupEncoder {
        VaultBackupEncoder(clock: clock, key: key, paddingMode: paddingMode)
    }
}

private func anyClock() -> EpochClock {
    EpochClock(makeCurrentTime: { 1234 })
}

private func anyKey() throws -> VaultKey {
    try VaultKey(key: Data(repeating: 0x34, count: 32), iv: Data(repeating: 0x35, count: 32))
}
