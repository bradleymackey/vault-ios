import Foundation
import TestHelpers
import XCTest
@testable import CryptoEngine

final class PBKDF2KeyDeriverTests: XCTestCase {
    func test_key_doesNotThrowForValidParameters() async {
        let sut = PBKDF2KeyDeriver(parameters: .fastForTesting)

        await XCTAssertNoThrow(try sut.key(password: anyData(), salt: anyData()))
    }

    func test_key_throwsIfMissingSalt() async {
        let sut = PBKDF2KeyDeriver(parameters: .fastForTesting)

        await XCTAssertThrowsError(try sut.key(password: anyData(), salt: emptyData()))
    }

    func test_key_generatesValidKeyWithSalt() async throws {
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")
        let sut = PBKDF2KeyDeriver(parameters: .fastForTesting)

        let key = try sut.key(password: password, salt: salt)
        XCTAssertEqual(key.toHexString(), "98daafce2dc5444d")
    }

    func test_key_generatesTheSameKeyMultipleTimes() async throws {
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")
        let sut = PBKDF2KeyDeriver(parameters: .fastForTesting)

        let expected = Data(hex: "98daafce2dc5444d")
        let keys = try [
            sut.key(password: password, salt: salt),
            sut.key(password: password, salt: salt),
            sut.key(password: password, salt: salt),
        ]
        XCTAssertEqual(keys, [expected, expected, expected])
    }

    func test_uniqueAlgorithmIdentifier_matchesParameters() {
        let sut = PBKDF2KeyDeriver(parameters: .init(
            keyLength: 123,
            iterations: 456,
            variant: .sha384
        ))

        XCTAssertEqual(sut.uniqueAlgorithmIdentifier, "PBKDF2<keyLength=123;iterations=456;variant=sha384>")
    }

    func test_userVisibleDescription_isPBKDF2() {
        let sut = PBKDF2KeyDeriver(parameters: .fastForTesting)

        XCTAssertEqual(sut.userVisibleDescription, "PBKDF2")
    }
}

extension PBKDF2KeyDeriver.Parameters {
    static var fastForTesting: Self {
        .init(keyLength: 8, iterations: 100, variant: .sha384)
    }
}
