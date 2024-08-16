import CryptoEngine
import Foundation
import FoundationExtensions
import TestHelpers
import VaultCore
import XCTest
@testable import VaultBackup

final class VaultBackupEncoderTests: XCTestCase {
    func test_createExportPayload_encryptedVaultDataIsExpectedVault() throws {
        let key = VaultKey(key: .repeating(byte: 0xAA), iv: .repeating(byte: 0xAB))
        let sut = makeSUT(key: key)

        let encryptedVault = try sut.createExportPayload(items: [], tags: [], userDescription: "hello world")

        // This is the encoded payload created by this test case, which is compressed using lzma:
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

        XCTAssertEqual(encryptedVault.data.toHexString(), """
        866de95d08a6b24751cdc4e9ab793585614c2062ba690a77762735d1abc866835ad0b54d1e3f29e9ffc4ad1d26a55e3a198ca9f685225042d331df50d64ad495f2a75c30000c6929c6e38a1bbfa16f0d3b81581c0d8f18ffc1df7ec773cfaa16068eb9b00c2de1268a459b3a6ae081dcdf81fe06d80ee23c8c44cb8ae6c61f519ffd7b1ce50efdbcd35e2a1e1eebd0571c924e0ad55f3f85a07b203005aea9e1314e85d36d065de2
        """)
        XCTAssertEqual(encryptedVault.authentication.toHexString(), """
        f5228102f094dbc0703270d39bac6b81
        """)
        XCTAssertEqual(encryptedVault.encryptionIV.toHexString(), """
        abababababababababababababababababababababababababababababababab
        """)
    }

    func test_createExportPayload_encryptedVaultDataIsExpectedVaultWithFixedPadding() throws {
        let key = VaultKey(key: .repeating(byte: 0xAA), iv: .repeating(byte: 0xAB))
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

        XCTAssertEqual(encryptedVault.data.toHexString(), """
        866de95d08a6b24751cdc4e9ab793585614c2062ba690a77762779d1b3c866835ad0b54d1e3f29e9ffc4ad1d26a55e3a198ca9f685225042d331df50d64ad495f2a75c30000c6929c6e38a1bbfa16f0d3b81581c0d8f18ffc1df7ec7de2cdcab847920ca4ce7a9bdf9c900c8853f9f12f19c36b0e3f9e3a79cd90a1be41291e436ffd83df34f31d6387933018eee38fd700ab2d10e5e3f858c3e64f77aafa31df76fda28c5060e4440ebf8358e3f5fa1
        """)
        XCTAssertEqual(encryptedVault.authentication.toHexString(), """
        c69f0292593e8e4c43afb3cbfcc815d0
        """)
        XCTAssertEqual(encryptedVault.encryptionIV.toHexString(), """
        abababababababababababababababababababababababababababababababab
        """)
    }

    func test_createExportPayload_includesKeySaltUnmodifiedInPayload() throws {
        let salt = Data.random(count: 34)
        let sut = makeSUT(key: anyKey(), keygenSalt: salt)

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
        keygenSignature: ApplicationKeyDeriver<Bits256>.Signature = .fastV1,
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

private func anyKey() -> VaultKey {
    .init(key: .random(), iv: .random())
}
