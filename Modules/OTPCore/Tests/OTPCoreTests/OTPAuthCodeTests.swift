import Foundation
import OTPCore
import XCTest

final class OTPAuthCodeTests: XCTestCase {
    func test_hotpGenerator_sixDigits() throws {
        let code = makeCode(digits: .six)
        let generator = code.data.hotpGenerator()

        try XCTAssertEqual(generator.code(counter: 0), 755_224)
    }

    func test_hotpGenerator_sevenDigits() throws {
        let code = makeCode(digits: .seven)
        let generator = code.data.hotpGenerator()

        try XCTAssertEqual(generator.code(counter: 0), 4_755_224)
    }

    func test_hotpGenerator_eightDigits() throws {
        let code = makeCode(digits: .eight)
        let generator = code.data.hotpGenerator()

        try XCTAssertEqual(generator.code(counter: 0), 84_755_224)
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

    private func makeCode(algorithm: OTPAuthAlgorithm = .sha1, digits: OTPAuthDigits = .six) -> GenericOTPAuthCode {
        GenericOTPAuthCode(
            type: .totp(),
            data: .init(secret: rfcSecret, algorithm: algorithm, digits: digits, accountName: "any")
        )
    }

    var rfcSecret: OTPAuthSecret {
        let data = Data(byteString: "12345678901234567890")
        return .init(data: data, format: .base32)
    }
}
