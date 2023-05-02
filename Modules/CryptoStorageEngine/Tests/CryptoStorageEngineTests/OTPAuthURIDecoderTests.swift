import CryptoStorageEngine
import Foundation
import XCTest

struct OTPAuthURIDecoder {
    enum URIDecodingError: Error {
        case invalidURI
        case invalidScheme
        case invalidType
        case invalidLabel
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
            accountName: decodeAccountName(uri: url)
        )
    }

    private func decodeAccountName(uri: URL) throws -> String {
        guard uri.pathComponents.count > 1 else {
            throw URIDecodingError.invalidLabel
        }
        let label = uri.pathComponents[1]
        let parts = label.split(separator: ":")
        guard let accountName = parts.last?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw URIDecodingError.invalidLabel
        }
        return String(accountName)
    }

    private func decodeType(uri: URL) throws -> OTPAuthType {
        guard let host = uri.host else {
            throw URIDecodingError.invalidType
        }
        switch host {
        case "totp":
            if let periodString = uri.queryParameters["period"], let period = UInt32(periodString) {
                return .totp(period: period)
            } else {
                return .totp()
            }
        case "hotp":
            if let counterStr = uri.queryParameters["counter"], let count = UInt32(counterStr) {
                return .hotp(counter: count)
            } else {
                return .hotp()
            }
        default:
            throw URIDecodingError.invalidType
        }
    }
}

private extension URL {
    var queryParameters: [String: String] {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return [:] }
        return queryItems.reduce(into: [String: String]()) { result, item in
            result[item.name] = item.value
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
        let value = "otpauth://totp/any"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.type.kind, .totp)
    }

    func test_decodeType_decodesHotpType() throws {
        let value = "otpauth://hotp/any"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.type.kind, .hotp)
    }

    func test_decodeType_throwsErrorForInvalidType() throws {
        let value = "otpauth://invalid/any"
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(string: value))
    }

    func test_decodeType_usesDefaultTotpTimingIfNotSpecified() throws {
        let value = "otpauth://totp/any"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        switch code.type {
        case let .totp(period):
            XCTAssertEqual(period, 30)
        default:
            XCTFail("Didn't decode totp")
        }
    }

    func test_decodeType_usesDefaultHotpCounterIfNotSpecified() throws {
        let value = "otpauth://hotp/any"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        switch code.type {
        case let .hotp(counter):
            XCTAssertEqual(counter, 0)
        default:
            XCTFail("Didn't decode hotp")
        }
    }

    func test_decodeType_decodesTotpPeriod() throws {
        let value = "otpauth://totp/any?period=69"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        switch code.type {
        case let .totp(period):
            XCTAssertEqual(period, 69)
        default:
            XCTFail("Didn't decode totp")
        }
    }

    func test_decodeType_decodesHotpCounter() throws {
        let value = "otpauth://hotp/any?counter=420"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        switch code.type {
        case let .hotp(counter):
            XCTAssertEqual(counter, 420)
        default:
            XCTFail("Didn't decode hotp")
        }
    }

    func test_decodeLabel_decodesAccountNameFromLabel() throws {
        let value = "otpauth://totp/Hello%20World"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.accountName, "Hello World")
    }

    func test_decodeLabel_decodesAccountNameWithIssuerFromLabel() throws {
        let value = "otpauth://totp/Issuer:Hello%20World"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.accountName, "Hello World")
    }

    func test_decodeLabel_decodesAccountNameWithIssuerFromLabelWithInvalidExtraColons() throws {
        let value = "otpauth://totp/Issuer:Extra:Colons:Invalid:Hello%20World"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.accountName, "Hello World")
    }

    func test_decodeLabel_decodesAccountNameTrimmingWhitespace() throws {
        let value = "otpauth://totp/Issuer:%20%20Hello%20World%20%20"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.accountName, "Hello World")
    }

    // MARK: - Helpers

    private func makeSUT() -> OTPAuthURIDecoder {
        OTPAuthURIDecoder()
    }
}
