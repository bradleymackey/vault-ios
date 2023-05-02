import CryptoStorageEngine
import Foundation
import XCTest

struct OTPAuthURIDecoder {
    enum URIDecodingError: Error {
        case invalidURI
        case invalidScheme
        case invalidType
        case invalidLabel
        case invalidAlgorithm
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
        let label = try decodeLabel(uri: url)
        return try OTPAuthCode(
            type: decodeType(uri: url),
            secret: .init(data: Data(), format: .base32),
            algorithm: decodeAlgorithm(uri: url),
            digits: decodeDigits(uri: url),
            accountName: label.accountName,
            issuer: label.issuer
        )
    }

    private func decodeDigits(uri: URL) throws -> OTPAuthDigits {
        guard let digits = uri.queryParameters["digits"], let value = Int(digits) else {
            return .default
        }
        return OTPAuthDigits(rawValue: value) ?? .default
    }

    private func decodeAlgorithm(uri: URL) throws -> OTPAuthAlgorithm {
        guard let algorithm = uri.queryParameters["algorithm"] else {
            return .default
        }
        switch algorithm {
        case "SHA1":
            return .sha1
        case "SHA256":
            return .sha256
        case "SHA512":
            return .sha512
        default:
            throw URIDecodingError.invalidAlgorithm
        }
    }

    private func decodeLabel(uri: URL) throws -> (accountName: String, issuer: String?) {
        guard uri.pathComponents.count > 1 else {
            throw URIDecodingError.invalidLabel
        }
        let label = uri.pathComponents[1]
        let parts = label.split(separator: ":")
        guard let accountName = parts.last?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw URIDecodingError.invalidLabel
        }
        var issuer = uri.queryParameters["issuer"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        if issuer == nil, parts.count > 1 {
            issuer = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return (String(accountName), issuer)
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

    func test_decodeIssuer_decodesNoIssuerIfNotPresent() throws {
        let value = "otpauth://totp/any"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertNil(code.issuer)
    }

    func test_decodeIssuer_decodesIssuerFromLabelIfNoParameter() throws {
        let value = "otpauth://totp/%20Some%20Issuer%20:any"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.issuer, "Some Issuer")
    }

    func test_decodeIssuer_decodesIssuerFromParameterIfNoLabel() throws {
        let value = "otpauth://totp/any?issuer=%20Some%20Issuer%20"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.issuer, "Some Issuer")
    }

    func test_decodeIssuer_decodesIssuerFromParameterWhenBothLabelAndParameter() throws {
        let value = "otpauth://totp/Disfavored:any?issuer=Preferred"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.issuer, "Preferred")
    }

    func test_decodeAlgorithm_defaultsToSHA1() throws {
        let value = "otpauth://totp/any"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.algorithm, .sha1)
    }

    func test_decodeAlgorithm_setsToSHA1() throws {
        let value = "otpauth://totp/any?algorithm=SHA1"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.algorithm, .sha1)
    }

    func test_decodeAlgorithm_setsToSHA256() throws {
        let value = "otpauth://totp/any?algorithm=SHA256"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.algorithm, .sha256)
    }

    func test_decodeAlgorithm_setsToSHA512() throws {
        let value = "otpauth://totp/any?algorithm=SHA512"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.algorithm, .sha512)
    }

    func test_decodeAlgorithm_throwsForInvalidAlgorithm() throws {
        let value = "otpauth://totp/any?algorithm=BAD"
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(string: value))
    }

    func test_decodeDigits_defaultstoSix() throws {
        let value = "otpauth://totp/any"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.digits, .six)
    }

    func test_decodeDigits_setsToSix() throws {
        let value = "otpauth://totp/any?digits=6"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.digits, .six)
    }

    func test_decodeDigits_setsToSeven() throws {
        let value = "otpauth://totp/any?digits=7"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.digits, .seven)
    }

    func test_decodeDigits_setsToEight() throws {
        let value = "otpauth://totp/any?digits=8"
        let sut = makeSUT()

        let code = try sut.decode(string: value)
        XCTAssertEqual(code.digits, .eight)
    }

    // MARK: - Helpers

    private func makeSUT() -> OTPAuthURIDecoder {
        OTPAuthURIDecoder()
    }
}
