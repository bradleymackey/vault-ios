import CryptoEngine
import Foundation
import TestHelpers
import XCTest

/// We don't actually want to run key derivation, as it may be very slow.
/// To check the algorithm's correctness, we verify the identifier.
///
/// Each respective version of each algorithm should never change, so it's always backwards compatible.
final class VaultAppKeyDeriversTests: XCTestCase {
    func test_V1_fast() {
        let fast = VaultAppKeyDerivers.V1.fast

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
        let secure = VaultAppKeyDerivers.V1.secure

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
}
