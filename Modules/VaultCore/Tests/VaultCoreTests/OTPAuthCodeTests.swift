import Foundation
import VaultCore
import XCTest

final class OTPAuthCodeTests: XCTestCase {
    func test_hotpGenerator_sixDigits() throws {
        let digits = OTPAuthDigits(value: 6)
        let code = makeCode(digits: digits)
        let generator = code.data.hotpGenerator()

        try XCTAssertEqual(generator.code(counter: 0), 755_224)
    }

    func test_hotpGenerator_sevenDigits() throws {
        let digits = OTPAuthDigits(value: 7)
        let code = makeCode(digits: digits)
        let generator = code.data.hotpGenerator()

        try XCTAssertEqual(generator.code(counter: 0), 4_755_224)
    }

    func test_hotpGenerator_eightDigits() throws {
        let digits = OTPAuthDigits(value: 8)
        let code = makeCode(digits: digits)
        let generator = code.data.hotpGenerator()

        try XCTAssertEqual(generator.code(counter: 0), 84_755_224)
    }

    func test_hotpGenerator_sixteenDigits() throws {
        let digits = OTPAuthDigits(value: 16)
        let code = makeCode(digits: digits)
        let generator = code.data.hotpGenerator()

        // This value is not actually sixteen digits long, the code should be prepended with zeros in this case.
        try XCTAssertEqual(generator.code(counter: 0), 1_284_755_224)
    }

    func test_hotpGenerator_maxDigits() throws {
        let digits = OTPAuthDigits(value: .max)
        let code = makeCode(digits: digits)
        let generator = code.data.hotpGenerator()

        // This value is not actually this many digits long, the code should be prepended with zeros in this case.
        try XCTAssertEqual(generator.code(counter: 0), 1_284_755_224)
    }

    func test_hotpGenerator_sha1() throws {
        let code = makeCode(algorithm: .sha1)
        let generator = code.data.hotpGenerator()

        try XCTAssertEqual(generator.code(counter: 0), 755_224)
    }

    func test_hotpGenerator_sha256() throws {
        let code = makeCode(algorithm: .sha256)
        let generator = code.data.hotpGenerator()

        try XCTAssertEqual(generator.code(counter: 0), 875_740)
    }

    func test_hotpGenerator_sha512() throws {
        let code = makeCode(algorithm: .sha512)
        let generator = code.data.hotpGenerator()

        try XCTAssertEqual(generator.code(counter: 0), 125_165)
    }

    // MARK: - Helpers

    private func makeCode(
        algorithm: OTPAuthAlgorithm = .default,
        digits: OTPAuthDigits = .default
    ) -> OTPAuthCode {
        OTPAuthCode(
            type: .totp(),
            data: .init(secret: rfcSecret, algorithm: algorithm, digits: digits, accountName: "any")
        )
    }

    var rfcSecret: OTPAuthSecret {
        let data = Data(byteString: "12345678901234567890")
        return .init(data: data, format: .base32)
    }
}
