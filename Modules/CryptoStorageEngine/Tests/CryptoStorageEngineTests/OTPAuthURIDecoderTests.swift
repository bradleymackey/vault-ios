import CryptoStorageEngine
import Foundation
import XCTest

struct OTPAuthURIDecoder {
    enum URIDecodingError: Error {
        case invalidURI
        case invalidScheme
    }

    public func decode(string: String) throws -> OTPAuthCode {
        guard
            let url = URL(string: string),
            let scheme = url.scheme
        else {
            throw URIDecodingError.invalidURI
        }
        guard scheme == "otpauth" else {
            throw URIDecodingError.invalidScheme
        }
        return OTPAuthCode(secret: .init(data: Data(), format: .base32), accountName: "any")
    }
}

final class OTPAuthURIDecoderTests: XCTestCase {
    func test_decode_invalidURIThrowsInvalidURIError() throws {
        let invalidCases = [
            "",
            "aaaaaaaaaaaaa",
            "notvalid",
            "123",
        ]
        for string in invalidCases {
            let sut = makeSUT()

            XCTAssertThrowsError(try sut.decode(string: string))
        }
    }

    func test_decodeScheme_invalidSchemeThrowsError() throws {
        let invalidCases = [
            "notvalid://",
            "://",
        ]
        for string in invalidCases {
            let sut = makeSUT()

            XCTAssertThrowsError(try sut.decode(string: string))
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> OTPAuthURIDecoder {
        OTPAuthURIDecoder()
    }
}
