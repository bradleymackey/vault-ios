import Foundation
import TestHelpers
import VaultCore
import XCTest
@testable import VaultBackup

final class VaultBackupDecoderTests: XCTestCase {
    func test_extractBackupPayload_decryptsVaultWithCorrectKey() throws {
        let key = Data(repeating: 0xAA, count: 32)
        let sut = makeSUT(key: key)

        let encryptedVault = EncryptedVault(
            data: Data(hex: """
            0050b32570c5c022cfab78cc8b592ea4467e1356fe76dff89c078ff3ace10\
            3d3ab72826b177505bada8cb5d66725b3b3ed5887a6ab2f9f6258ce927b13\
            e7e68c3142c6b487141659225347c2a5b21b7eead891334de0323938e6599\
            14f478e6f1995637a201b45c1c15ff9cf02d8a3e44ec07029cc2b9e4f45d0\
            ec6b60b6e9e8ac109a946e9e6391
            """),
            authentication: Data(hex: """
            837b99a7c9d7e7b4cb56fe2f863d6034
            """),
            encryptionIV: Data(hex: """
            abababababababababababababababababababababababababababababababab
            """)
        )

        let backup = try sut.extractBackupPayload(from: encryptedVault)

        XCTAssertEqual(backup.items, [])
        XCTAssertEqual(backup.obfuscationPadding, Data())
        XCTAssertEqual(backup.version, .v1_0_0)
        XCTAssertEqual(backup.created, .init(timeIntervalSince1970: 1234))
    }

    func test_extractBackupPayload_failsToDecryptGoodPayloadForInvalidKey() throws {
        let key = Data(repeating: 0xBB, count: 32)
        let sut = makeSUT(key: key)

        let encryptedVault = EncryptedVault(
            data: Data(hex: """
            0050b32570c5c022cfab78cc8b592ea4467e1356fe76dff89c078ff3ace10\
            3d3ab72826b177505bada8cb5d66725b3b3ed5887a6ab2f9f6258ce927b13\
            e7e68c3142c6b487141659225347c2a5b21b7eead891334de0323938e6599\
            14f478e6f1995637a201b45c1c15ff9cf02d8a3e44ec07029cc2b9e4f45d0\
            ec6b60b6e9e8ac109a946e9e6391
            """),
            authentication: Data(hex: """
            837b99a7c9d7e7b4cb56fe2f863d6034
            """),
            encryptionIV: Data(hex: """
            abababababababababababababababababababababababababababababababab
            """)
        )

        XCTAssertThrowsError(try sut.extractBackupPayload(from: encryptedVault))
    }

    func test_extractBackupPayload_failsToDecryptMalformedAuthentication() throws {
        let key = Data(repeating: 0xAA, count: 32)
        let sut = makeSUT(key: key)

        let encryptedVault = EncryptedVault(
            data: Data(hex: """
            0050b32570c5c022cfab78cc8b592ea4467e1356fe76dff89c078ff3ace10\
            3d3ab72826b177505bada8cb5d66725b3b3ed5887a6ab2f9f6258ce927b13\
            e7e68c3142c6b487141659225347c2a5b21b7eead891334de0323938e6599\
            14f478e6f1995637a201b45c1c15ff9cf02d8a3e44ec07029cc2b9e4f45d0\
            ec6b60b6e9e8ac109a946e9e6391
            """),
            // malformed
            authentication: Data(hex: """
            837b99a7c9d7e7b4cb56fe2f863d6035
            """),
            encryptionIV: Data(hex: """
            abababababababababababababababababababababababababababababababab
            """)
        )

        XCTAssertThrowsError(try sut.extractBackupPayload(from: encryptedVault))
    }
}

// MARK: - Helpers

extension VaultBackupDecoderTests {
    private func makeSUT(key: Data) -> VaultBackupDecoder {
        VaultBackupDecoder(key: key)
    }
}
