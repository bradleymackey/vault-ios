import CryptoStorageEngine
import Foundation
import XCTest

struct OTPAuthURIEncoder {
    enum URIEncodingError: Error {
        case badURIComponents
    }

    func encode(code: OTPAuthCode) throws -> String {
        var components = URLComponents()
        components.scheme = "otpauth"
        components.host = formatted(type: code.type)
        components.path = "/" + formattedLabel(code: code)
        if let issuer = code.issuer {
            components.queryItems = [
                URLQueryItem(name: "issuer", value: issuer),
            ]
        }
        guard let string = components.string else {
            throw URIEncodingError.badURIComponents
        }
        return string
    }

    private func formattedLabel(code: OTPAuthCode) -> String {
        if let issuer = code.issuer {
            return "\(issuer):\(code.accountName)"
        } else {
            return code.accountName
        }
    }

    private func formatted(type: OTPAuthType) -> String {
        switch type {
        case .totp:
            return "totp"
        case .hotp:
            return "hotp"
        }
    }
}

final class OTPAuthURIEncoderTests: XCTestCase {
    func test_encode_totpUsesTOTPType() throws {
        let code = makeCode(type: .totp, accountName: "")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        XCTAssertEqual(encoded, "otpauth://totp/")
    }

    func test_encode_hotpUsesHOTPType() throws {
        let code = makeCode(type: .hotp, accountName: "")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        XCTAssertEqual(encoded, "otpauth://hotp/")
    }

    func test_encode_accountNameOnlyRendersAsStandaloneLabel() throws {
        let code = makeCode(type: .hotp, accountName: "Account")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        XCTAssertEqual(encoded, "otpauth://hotp/Account")
    }

    func test_encode_labelIncludesIssuerAndAccountIssuerParameter() throws {
        let code = makeCode(type: .hotp, accountName: "Account", issuer: "Issuer")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        XCTAssertEqual(encoded, "otpauth://hotp/Issuer:Account?issuer=Issuer")
    }

    func test_encode_labelEncodesSpecialCharacters() throws {
        let code = makeCode(type: .hotp, accountName: "Account Name", issuer: "Issuer Name")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        XCTAssertEqual(encoded, "otpauth://hotp/Issuer%20Name:Account%20Name?issuer=Issuer%20Name")
    }

    // MARK: - Helpers

    private func makeSUT() -> OTPAuthURIEncoder {
        OTPAuthURIEncoder()
    }

    private func makeCode(type: OTPAuthType, accountName: String, issuer: String? = nil) -> OTPAuthCode {
        OTPAuthCode(type: type, secret: .init(data: Data(), format: .base32), accountName: accountName, issuer: issuer)
    }
}
