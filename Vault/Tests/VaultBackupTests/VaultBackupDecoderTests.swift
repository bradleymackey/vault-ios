import Foundation
import TestHelpers
import VaultCore
import XCTest
@testable import VaultBackup

final class VaultBackupDecoderTests: XCTestCase {
    func test_extractBackupPayload_throwsForIncompatibleVersion() throws {
        let key = Data(repeating: 0xAA, count: 32)
        let sut = makeSUT(key: key)

        var encryptedVault = EncryptedVault(
            data: Data(),
            authentication: Data(),
            encryptionIV: Data(),
            keygenSalt: Data(),
            keygenSignature: .fastV1
        )
        encryptedVault.version = "2.0.0"

        XCTAssertThrowsError(try sut.extractBackupPayload(from: encryptedVault))
    }

    func test_extractBackupPayload_decryptsVaultWithCorrectKey() throws {
        let key = Data(repeating: 0xAA, count: 32)
        let sut = makeSUT(key: key)

        let encryptedVault = EncryptedVault(
            data: Data(hex: """
            0050b32570c5c022cfab78cc8b592ea4467e1356fe76dff89c078ff3ace103d3ab72826b177505bada8cb5d66725b3b3ed5887a6ab2f9f6258ce927b13e7e68c3142c6b487141659225347c2a5b21a6ce8d9ec7712b30a415bb60da50c238c6f01c0327737284dcb924be4d41ec8e8a72ac270319a6c845940d3ed6937e3bba6f91c86b07e9c4b9ad657b3eb9185f27726b3ee3a606e11b5ae3593
            """),
            authentication: Data(hex: """
            8a90eab22324cbf12366fda7f7006437
            """),
            encryptionIV: Data(hex: """
            abababababababababababababababababababababababababababababababab
            """),
            keygenSalt: Data(),
            keygenSignature: .fastV1
        )

        let backup = try sut.extractBackupPayload(from: encryptedVault)

        XCTAssertEqual(backup.items, [])
        XCTAssertEqual(backup.obfuscationPadding, Data())
        XCTAssertEqual(backup.version, "1.0.0")
        XCTAssertEqual(backup.created, .init(timeIntervalSince1970: 1234))
    }

    func test_extractBackupPayload_failsToDecryptGoodPayloadForInvalidKey() throws {
        let key = Data(repeating: 0xBB, count: 32)
        let sut = makeSUT(key: key)

        let encryptedVault = EncryptedVault(
            data: Data(hex: """
            0050b32570c5c022cfab78cc8b592ea4467e1356fe76dff89c078ff3ace103d3ab72826b177505bada8cb5d66725b3b3ed5887a6ab2f9f6258ce927b13e7e68c3142c6b487141659225347c2a5b21a6ce8d9ec7712b30a415bb60da50c238c6f01c0327737284dcb924be4d41ec8e8a72ac270319a6c845940d3ed6937e3bba6f91c86b07e9c4b9ad657b3eb9185f27726b3ee3a606e11b5ae3593
            """),
            authentication: Data(hex: """
            8a90eab22324cbf12366fda7f7006437
            """),
            encryptionIV: Data(hex: """
            abababababababababababababababababababababababababababababababab
            """),
            keygenSalt: Data(),
            keygenSignature: .fastV1
        )

        XCTAssertThrowsError(try sut.extractBackupPayload(from: encryptedVault))
    }

    func test_extractBackupPayload_failsToDecryptMalformedAuthentication() throws {
        let key = Data(repeating: 0xAA, count: 32)
        let sut = makeSUT(key: key)

        let encryptedVault = EncryptedVault(
            data: Data(hex: """
            0050b32570c5c022cfab78cc8b592ea4467e1356fe76dff89c078ff3ace103d3ab72826b177505bada8cb5d66725b3b3ed5887a6ab2f9f6258ce927b13e7e68c3142c6b487141659225347c2a5b21a6ce8d9ec7712b30a415bb60da50c238c6f01c0327737284dcb924be4d41ec8e8a72ac270319a6c845940d3ed6937e3bba6f91c86b07e9c4b9ad657b3eb9185f27726b3ee3a606e11b5ae3593
            """),
            // malformed
            authentication: Data(hex: """
            837b99a7c9d7e7b4cb56fe2f863d6035
            """),
            encryptionIV: Data(hex: """
            abababababababababababababababababababababababababababababababab
            """),
            keygenSalt: Data(),
            keygenSignature: .fastV1
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
