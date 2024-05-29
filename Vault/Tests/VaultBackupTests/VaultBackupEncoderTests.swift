import Foundation
import TestHelpers
import VaultCore
import XCTest
@testable import VaultBackup

final class VaultBackupEncoderTests: XCTestCase {
    func test_createExportPayload_setsCreatedDateFromCurrentClockTime() throws {
        let clock = EpochClock(makeCurrentTime: { 1_234_567 })
        let key = try anyKey()
        let sut = makeSUT(clock: clock, key: key)

        let payload = try sut.createExportPayload(items: [], userDescription: "")

        XCTAssertEqual(payload.created, Date(timeIntervalSince1970: 1_234_567))
    }

    func test_createExportPayload_setsUserDescriptionFromParameter() throws {
        let key = try anyKey()
        let sut = makeSUT(key: key)

        let payload = try sut.createExportPayload(items: [], userDescription: "hello world")

        XCTAssertEqual(payload.userDescription, "hello world")
    }

    func test_createExportPayload_encryptedVaultDataIsExpectedVault() throws {
        let key = try VaultKey(key: Data(repeating: 0xAA, count: 32), iv: Data(repeating: 0xAB, count: 32))
        let sut = makeSUT(key: key)

        let payload = try sut.createExportPayload(items: [], userDescription: "hello world")

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

        XCTAssertEqual(payload.encryptedVault.data.toHexString(), """
        0050b32570c5c022cfab78cc8b592ea4467e1356fe76dff89c078ff3ace10\
        3d3ab72826b177505bada8cb5d66725b3b3ed5887a6ab2f9f6258ce927b13\
        e7e68c3142c6b487141659225347c2a5b21b7eead891334de0323938e6599\
        14f478e6f1995637a201b45c1c15ff9cf02d8a3e44ec07029cc2b9e4f45d0\
        ec6b60b6e9e8ac109a946e9e6391
        """)
        XCTAssertEqual(payload.encryptedVault.authentication.toHexString(), """
        837b99a7c9d7e7b4cb56fe2f863d6034
        """)
        XCTAssertEqual(payload.encryptedVault.encryptionIV.toHexString(), """
        abababababababababababababababababababababababababababababababab
        """)
    }
}

// MARK: - Helpers

extension VaultBackupEncoderTests {
    private func makeSUT(
        clock: EpochClock = anyClock(),
        key: VaultKey
    ) -> VaultBackupEncoder {
        VaultBackupEncoder(clock: clock, key: key)
    }
}

private func anyClock() -> EpochClock {
    EpochClock(makeCurrentTime: { 1234 })
}

private func anyKey() throws -> VaultKey {
    try VaultKey(key: Data(repeating: 0x34, count: 32), iv: Data(repeating: 0x35, count: 32))
}
