import CryptoStorageEngine
import Foundation
import XCTest

struct OTPAuthURIDecoder {
    enum URIDecodingError: Error {
        case invalidURI
    }

    public func decode(string: String) throws -> OTPAuthCode {
        guard
            let url = URL(string: string),
            let scheme = url.scheme
        else {
            throw URIDecodingError.invalidURI
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

    // MARK: - Helpers

    private func makeSUT() -> OTPAuthURIDecoder {
        OTPAuthURIDecoder()
    }
}
