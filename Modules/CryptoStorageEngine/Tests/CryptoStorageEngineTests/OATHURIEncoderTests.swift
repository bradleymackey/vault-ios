import CryptoStorageEngine
import Foundation
import XCTest

struct OATHURIEncoder {
    func encode(code _: OATHCode) throws -> String {
        "otpauth://totp/?secret="
    }
}

final class OATHURIEncoderTests: XCTestCase {
    func test_encode_emptyTOTPHasCodePrefix() throws {
        let sut = makeSUT()
        let empty = makeEmptyTOTP()

        let encoded = try sut.encode(code: empty)

        XCTAssertEqual(encoded, "otpauth://totp/?secret=")
    }

    // MARK: - Helpers

    private func makeSUT() -> OATHURIEncoder {
        OATHURIEncoder()
    }

    private func makeEmptyTOTP() -> OATHCode {
        OATHCode(
            secret: .init(data: Data(), format: .base32),
            label: "any"
        )
    }
}
