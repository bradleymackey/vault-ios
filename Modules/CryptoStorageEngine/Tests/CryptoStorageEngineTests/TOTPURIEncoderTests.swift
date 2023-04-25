import CryptoStorageEngine
import Foundation
import XCTest

struct TOTPURIEncoder {
    func encode(code _: TOTPCode) throws -> String {
        "otpauth://totp/?secret="
    }
}

final class TOTPURIEncoderTests: XCTestCase {
    func test_encode_emptyTOTPHasCodePrefix() throws {
        let sut = makeSUT()
        let empty = makeEmptyTOTP()

        let encoded = try sut.encode(code: empty)

        XCTAssertEqual(encoded, "otpauth://totp/?secret=")
    }

    // MARK: - Helpers

    private func makeSUT() -> TOTPURIEncoder {
        TOTPURIEncoder()
    }

    private func makeEmptyTOTP() -> TOTPCode {
        TOTPCode(
            secret: .init(data: Data(), format: .base32),
            label: "any"
        )
    }
}
