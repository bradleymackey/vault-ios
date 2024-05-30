import Foundation
import TestHelpers
import XCTest
@testable import CryptoEngine

final class PBKDF2KeyDeriverTests: XCTestCase {
    func test_init_doesNotThrowForValidParameters() async {
        let sut = PBKDF2KeyDeriver(parameters: .fastForTesting)

        await XCTAssertNoThrow(try sut.key(password: anyData(), salt: anyData()))
    }

    func test_init_throwsIfMissingSalt() async {
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
}

extension PBKDF2KeyDeriver.Parameters {
    static var fastForTesting: Self {
        .init(keyLength: 8, iterations: 100, variant: .sha384)
    }
}
