import CryptoEngine
import Foundation
import FoundationExtensions
import TestHelpers
import XCTest
@testable import VaultKeygen

/// We don't actually want to run key derivation, as it may be very slow.
/// To check the algorithm's correctness, we verify the identifier.
///
/// Each respective version of each algorithm should never change, so it's always backwards compatible.
final class VaultKeyDeriverTests: XCTestCase {
    func test_V1_fast() {
        let fast = VaultKeyDeriver.V1.fast

        XCTAssertEqual(fast.signature, .fastV1)
        XCTAssertEqual(fast.signature.userVisibleDescription, "Vault Default – FAST v1")
        XCTAssertEqual(fast.uniqueAlgorithmIdentifier, """
        COMBINATION<\
        PBKDF2<keyLength=32;iterations=2000;variant=sha384>|\
        HKDF<keyLength=32;variant=sha3_sha512>|\
        SCRYPT<keyLength=32;costFactor=64;blockSizeFactor=4;parallelizationFactor=1>\
        >
        """)
    }

    func test_V1_secure() {
        let secure = VaultKeyDeriver.V1.secure

        XCTAssertEqual(secure.signature, .secureV1)
        XCTAssertEqual(secure.signature.userVisibleDescription, "Vault Default – SECURE v1")
        XCTAssertEqual(secure.uniqueAlgorithmIdentifier, """
        COMBINATION<\
        PBKDF2<keyLength=32;iterations=5452351;variant=sha384>|\
        HKDF<keyLength=32;variant=sha3_sha512>|\
        SCRYPT<keyLength=32;costFactor=262144;blockSizeFactor=8;parallelizationFactor=1>\
        >
        """)
    }

    func test_lookupSignature_looksUpCorrect() {
        let signatures = VaultKeyDeriver.Signature.allCases
        for signature in signatures {
            let result = VaultKeyDeriver.lookup(signature: signature)

            XCTAssertEqual(result.signature, signature)
        }
    }

    func test_createEncryptionKey_usesRandomSalt() throws {
        let sut = VaultKeyDeriver.testing

        var seenKeys = Set<KeyData<Bits256>>()
        var seenSalt = Set<Data>()
        var seenKeyDeriver = Set<VaultKeyDeriver.Signature>()
        for _ in 0 ..< 100 {
            let key = try sut.createEncryptionKey(password: "password")
            seenKeys.insert(key.key)
            seenSalt.insert(key.salt)
            seenKeyDeriver.insert(key.keyDervier)
        }

        XCTAssertEqual(seenKeys.count, 100)
        XCTAssertEqual(seenSalt.count, 100)
        XCTAssertEqual(seenKeyDeriver.count, 1)
        XCTAssertEqual(seenKeyDeriver.first, .testing)
    }

    func test_recreateEncryptionKey_usesTheSameSalt() throws {
        let salt = Data(hex: "aabbccddeeff")
        let sut = VaultKeyDeriver.testing

        var seenKeys = Set<KeyData<Bits256>>()
        var seenSalt = Set<Data>()
        var seenKeyDeriver = Set<VaultKeyDeriver.Signature>()

        for _ in 0 ..< 100 {
            let key = try sut.recreateEncryptionKey(password: "password", salt: salt)
            seenKeys.insert(key.key)
            seenSalt.insert(key.salt)
            seenKeyDeriver.insert(key.keyDervier)
        }

        XCTAssertEqual(seenKeys.count, 1)
        XCTAssertEqual(seenSalt.count, 1)
        XCTAssertEqual(seenKeyDeriver.count, 1)
        XCTAssertEqual(
            seenKeys.first?.data.toHexString(),
            "b8ab51d4c385654810dbcc8e860426143a7b61a4273805ba9596b1f9c00530c6"
        )
        XCTAssertEqual(seenSalt.first?.toHexString(), "aabbccddeeff")
        XCTAssertEqual(seenKeyDeriver.first, .testing)
    }
}
