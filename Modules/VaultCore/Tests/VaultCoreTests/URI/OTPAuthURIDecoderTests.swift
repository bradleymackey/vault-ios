import Foundation
import VaultCore
import XCTest

final class OTPAuthURIDecoderTests: XCTestCase {
    func test_decodeScheme_invalidSchemeThrowsError() throws {
        let invalidCases = [
            "http://",
            "http://example.com",
            "https://",
            "https://example.com",
            "notvalid://",
            "notvalid://example",
            "://",
        ]
        for string in invalidCases {
            let sut = makeSUT()

            XCTAssertThrowsError(try sut.decode(string))
        }
    }

    func test_decodeType_decodesTotpType() throws {
        let value = "otpauth://totp/any"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.type.kind, .totp)
    }

    func test_decodeType_decodesHotpType() throws {
        let value = "otpauth://hotp/any"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.type.kind, .hotp)
    }

    func test_decodeType_throwsErrorForInvalidType() throws {
        let value = "otpauth://invalid/any"
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(value))
    }

    func test_decodeType_usesDefaultTotpTimingIfNotSpecified() throws {
        let value = "otpauth://totp/any"
        let sut = makeSUT()

        let code = try sut.decode(value)
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

        let code = try sut.decode(value)
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

        let code = try sut.decode(value)
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

        let code = try sut.decode(value)
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

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.accountName, "Hello World")
    }

    func test_decodeLabel_decodesAccountNameWithIssuerFromLabel() throws {
        let value = "otpauth://totp/Issuer:Hello%20World"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.accountName, "Hello World")
    }

    func test_decodeLabel_decodesAccountNameWithIssuerFromLabelWithInvalidExtraColons() throws {
        let value = "otpauth://totp/Issuer:Extra:Colons:Invalid:Hello%20World"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.accountName, "Hello World")
    }

    func test_decodeLabel_decodesAccountNameTrimmingWhitespace() throws {
        let value = "otpauth://totp/Issuer:%20%20Hello%20World%20%20"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.accountName, "Hello World")
    }

    func test_decodeIssuer_decodesNoIssuerIfNotPresent() throws {
        let value = "otpauth://totp/any"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertNil(code.data.issuer)
    }

    func test_decodeIssuer_decodesIssuerFromLabelIfNoParameter() throws {
        let value = "otpauth://totp/%20Some%20Issuer%20:any"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.issuer, "Some Issuer")
    }

    func test_decodeIssuer_decodesIssuerFromParameterIfNoLabel() throws {
        let value = "otpauth://totp/any?issuer=%20Some%20Issuer%20"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.issuer, "Some Issuer")
    }

    func test_decodeIssuer_decodesIssuerFromParameterWhenBothLabelAndParameter() throws {
        let value = "otpauth://totp/Disfavored:any?issuer=Preferred"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.issuer, "Preferred")
    }

    func test_decodeAlgorithm_defaultsToSHA1() throws {
        let value = "otpauth://totp/any"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.algorithm, .sha1)
    }

    func test_decodeAlgorithm_setsToSHA1() throws {
        let value = "otpauth://totp/any?algorithm=SHA1"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.algorithm, .sha1)
    }

    func test_decodeAlgorithm_setsToSHA256() throws {
        let value = "otpauth://totp/any?algorithm=SHA256"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.algorithm, .sha256)
    }

    func test_decodeAlgorithm_setsToSHA512() throws {
        let value = "otpauth://totp/any?algorithm=SHA512"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.algorithm, .sha512)
    }

    func test_decodeAlgorithm_throwsForInvalidAlgorithm() throws {
        let value = "otpauth://totp/any?algorithm=BAD"
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(value))
    }

    func test_decodeDigits_defaultstoSix() throws {
        let value = "otpauth://totp/any"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.digits.value, 6)
    }

    func test_decodeDigits_setsToSix() throws {
        let value = "otpauth://totp/any?digits=6"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.digits.value, 6)
    }

    func test_decodeDigits_setsToEight() throws {
        let value = "otpauth://totp/any?digits=8"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.digits.value, 8)
    }

    func test_decodeDigits_setsTo12() throws {
        let value = "otpauth://totp/any?digits=12"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.digits.value, 12)
    }

    func test_decodeDigits_throwsForNegativeNumber() throws {
        let value = "otpauth://totp/any?digits=-10"
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(value))
    }

    func test_decodeDigits_throwsForTooLargeNumber() throws {
        let value = "otpauth://totp/any?digits=80000"
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.decode(value))
    }

    func test_decodeSecret_defaultsToEmptySecretBase32() throws {
        let value = "otpauth://totp/any"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.secret.data, Data())
        XCTAssertEqual(code.data.secret.format, .base32)
    }

    func test_decodeSecret_decodesBase32Secret() throws {
        let value = "otpauth://totp/any?secret=5372UEJC"
        let sut = makeSUT()

        let code = try sut.decode(value)
        let expectedBytes: [UInt8] = [0xEE, 0xFF, 0xAA, 0x11, 0x22]
        XCTAssertEqual(code.data.secret.data, Data(expectedBytes))
        XCTAssertEqual(code.data.secret.format, .base32)
    }

    func test_decodeSecret_decodesBase32SecretWithPadding() throws {
        let value = "otpauth://totp/any?secret=5372UEJC77XA%3D%3D%3D%3D"
        let sut = makeSUT()

        let code = try sut.decode(value)
        let expectedBytes: [UInt8] = [0xEE, 0xFF, 0xAA, 0x11, 0x22, 0xFF, 0xEE]
        XCTAssertEqual(code.data.secret.data, Data(expectedBytes))
        XCTAssertEqual(code.data.secret.format, .base32)
    }

    func test_decodeSecret_invalidBase32ReturnsNoDataInSecret() throws {
        let value = "otpauth://totp/any?secret=ee~~~"
        let sut = makeSUT()

        let code = try sut.decode(value)
        XCTAssertEqual(code.data.secret.data, Data())
        XCTAssertEqual(code.data.secret.format, .base32)
    }

    func test_decode_decodesAllParameters() throws {
        let value = "otpauth://totp/Issuer:Account?period=69&digits=8&algorithm=SHA512&issuer=Issuer&secret=5372UEJC"
        let sut = makeSUT()

        let code = try sut.decode(value)
        let expectedBytes: [UInt8] = [0xEE, 0xFF, 0xAA, 0x11, 0x22]
        XCTAssertEqual(code.data.secret.data, Data(expectedBytes))
        XCTAssertEqual(code.data.secret.format, .base32)
        XCTAssertEqual(code.data.algorithm, .sha512)
        XCTAssertEqual(code.data.digits.value, 8)
        XCTAssertEqual(code.data.issuer, "Issuer")
        XCTAssertEqual(code.data.accountName, "Account")
        switch code.type {
        case let .totp(period):
            XCTAssertEqual(period, 69)
        default:
            XCTFail("Did not decode totp")
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> OTPAuthURIDecoder {
        OTPAuthURIDecoder()
    }
}

private extension OTPAuthURIDecoder {
    func decode(_ testCaseValue: String) throws -> OTPAuthCode {
        let uri = try XCTUnwrap(OTPAuthURI(string: testCaseValue), "Not a valid url.")
        return try decode(uri: uri)
    }
}
