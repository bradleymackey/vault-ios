import Foundation
import FoundationExtensions
import TestHelpers
import XCTest
@testable import CryptoEngine

final class PBKDF2KeyDeriverTests: XCTestCase {
    func test_key_doesNotThrowForValidParameters() async {
        let sut = PBKDF2KeyDeriver<Bits64>(parameters: .fastForTesting)

        await XCTAssertNoThrow(try sut.key(password: anyData(), salt: anyData()))
    }

    func test_key_throwsIfMissingSalt() async {
        let sut = PBKDF2KeyDeriver<Bits64>(parameters: .fastForTesting)

        await XCTAssertThrowsError(try sut.key(password: anyData(), salt: emptyData()))
    }

    func test_key_generatesValidKeyWithSalt() async throws {
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")
        let sut = PBKDF2KeyDeriver<Bits64>(parameters: .fastForTesting)

        let key = try sut.key(password: password, salt: salt)
        XCTAssertEqual(key.data.toHexString(), "98daafce2dc5444d")
    }

    func test_key_generatesTheSameKeyMultipleTimes() async throws {
        let password = Data(byteString: "hello world")
        let salt = Data(hex: "ABCDEF")
        let sut = PBKDF2KeyDeriver<Bits64>(parameters: .fastForTesting)

        let expected = try KeyData<Bits64>(data: Data(hex: "98daafce2dc5444d"))
        let keys = try [
            sut.key(password: password, salt: salt),
            sut.key(password: password, salt: salt),
            sut.key(password: password, salt: salt),
        ]
        XCTAssertEqual(keys, [expected, expected, expected])
    }

    func test_uniqueAlgorithmIdentifier_matchesParameters() {
        let sut = PBKDF2KeyDeriver<Bits64>(parameters: .init(
            iterations: 456,
            variant: .sha384
        ))

        XCTAssertEqual(sut.uniqueAlgorithmIdentifier, "PBKDF2<keyLength=8;iterations=456;variant=sha384>")
    }
}

extension PBKDF2KeyDeriver.Parameters {
    static var fastForTesting: Self {
        .init(iterations: 100, variant: .sha384)
    }
}
