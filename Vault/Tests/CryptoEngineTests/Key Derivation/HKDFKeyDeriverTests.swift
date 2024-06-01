import Foundation
import TestHelpers
import XCTest
@testable import CryptoEngine

final class HKDFKeyDeriverTests: XCTestCase {
    func test_key_doesNotThrowForValidParameters() {
        let sut = HKDFKeyDeriver(parameters: .fastForTesting)

        XCTAssertNoThrow(try sut.key(password: anyData(), salt: anyData()))
    }

    func test_key_doesNotThrowIfNotMissingSalt() {
        let sut = HKDFKeyDeriver(parameters: .fastForTesting)

        XCTAssertNoThrow(try sut.key(password: anyData(), salt: emptyData()))
    }

    func test_key_generatesValidKeyWithSalt() async throws {
        // https://gchq.github.io/CyberChef/#recipe=Derive_HKDF_key(%7B'option':'Hex','string':'ABCDEF'%7D,%7B'option':'Hex','string':''%7D,'SHA256','with%20salt',8)&input=aGVsbG8gd29ybGQ
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")
        let sut = HKDFKeyDeriver(parameters: .fastForTesting)

        let key = try sut.key(password: password, salt: salt)
        XCTAssertEqual(key.toHexString(), "e8fd40d5582c09ee")
    }

    func test_uniqueAlgorithmIdentifier_matchesParameters() {
        let sut = HKDFKeyDeriver(parameters: .init(
            keyLength: 456,
            variant: .sha3_sha512
        ))

        XCTAssertEqual(sut.uniqueAlgorithmIdentifier, "HKDF<keyLength=456;variant=sha3_sha512>")
    }

    func test_userVisibleDescription_isHKDF() {
        let sut = HKDFKeyDeriver(parameters: .fastForTesting)

        XCTAssertEqual(sut.userVisibleDescription, "HKDF")
    }
}

extension HKDFKeyDeriver.Parameters {
    static var fastForTesting: Self {
        .init(keyLength: 8, variant: .sha256)
    }
}
