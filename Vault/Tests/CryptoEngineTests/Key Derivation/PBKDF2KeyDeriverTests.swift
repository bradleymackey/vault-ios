import Foundation
import TestHelpers
import XCTest
@testable import CryptoEngine

final class PBKDF2KeyDeriverTests: XCTestCase {
    func test_init_doesNotThrowForValidParameters() {
        let params = PBKDF2KeyDeriver.Parameters(
            keyLength: 32,
            iterations: 100_000,
            variant: .sha384
        )
        XCTAssertNoThrow(try PBKDF2KeyDeriver(password: anyData(), salt: anyData(), parameters: params))
    }

    func test_init_throwsIfMissingSalt() {
        let params = PBKDF2KeyDeriver.Parameters(
            keyLength: 32,
            iterations: 100_000,
            variant: .sha384
        )
        XCTAssertThrowsError(try PBKDF2KeyDeriver(password: anyData(), salt: emptyData(), parameters: params))
    }

    func test_key_generatesValidKeyWithSalt() async throws {
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")

        let sut = try PBKDF2KeyDeriver(password: password, salt: salt, parameters: .fastForTesting)
        let key = try await sut.key()
        XCTAssertEqual(key.toHexString(), "98daafce2dc5444d")
    }

    func test_key_generatesTheSameKeyMultipleTimes() async throws {
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")

        let sut = try PBKDF2KeyDeriver(password: password, salt: salt, parameters: .fastForTesting)
        let expected = Data(hex: "98daafce2dc5444d")
        let keys = try await [sut.key(), sut.key(), sut.key()]
        XCTAssertEqual(keys, [expected, expected, expected])
    }
}

extension PBKDF2KeyDeriver.Parameters {
    static var fastForTesting: Self {
        .init(keyLength: 8, iterations: 100, variant: .sha384)
    }
}
