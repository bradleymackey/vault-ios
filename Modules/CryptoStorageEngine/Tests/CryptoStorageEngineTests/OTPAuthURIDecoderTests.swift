import CryptoStorageEngine
import Foundation
import XCTest

struct OTPAuthURIDecoder {
    enum URIDecodingError: Error {
        case invalidURI
        case invalidScheme
        case invalidType
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
        return try OTPAuthCode(
            type: decodeType(uri: url),
            secret: .init(data: Data(), format: .base32),
            accountName: "any"
        )
    }

    private func decodeType(uri: URL) throws -> OTPAuthType {
        guard let host = uri.host else {
            throw URIDecodingError.invalidType
        }
        switch host {
        case "totp":
            return .totp()
        case "hotp":
            return .hotp()
        default:
            throw URIDecodingError.invalidType
        }
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

    func test_decodeType_decodesTotpType() throws {
        let value = "otpauth://totp/"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.type.kind, .totp)
    }

    func test_decodeType_decodesHotpType() throws {
        let value = "otpauth://hotp/"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.type.kind, .hotp)
    }

    func test_decodeType_throwsErrorForInvalidType() throws {
        let value = "otpauth://invalid/"
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(string: value))
    }

    // MARK: - Helpers

    private func makeSUT() -> OTPAuthURIDecoder {
        OTPAuthURIDecoder()
    }
}
