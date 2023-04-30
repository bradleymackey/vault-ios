import CryptoStorageEngine
import Foundation
import XCTest

enum OATHType: String {
    case totp
    case hotp
}

struct OATHURI {
    let scheme: String = "otpauth"
    var type: OATHType
    var accountName: String
    var issuer: String?
}

struct OATHURIEncoder {
    enum URIEncodingError: Error {
        case badURIComponents
    }

    func encode(uri: OATHURI) throws -> String {
        var components = URLComponents()
        components.scheme = uri.scheme
        components.host = formatted(type: uri.type)
        components.path = "/" + formattedLabel(uri: uri)
        if let issuer = uri.issuer {
            components.queryItems = [
                URLQueryItem(name: "issuer", value: issuer),
            ]
        }
        guard let string = components.string else {
            throw URIEncodingError.badURIComponents
        }
        return string
    }

    private func formattedLabel(uri: OATHURI) -> String {
        if let issuer = uri.issuer {
            return "\(issuer):\(uri.accountName)"
        } else {
            return uri.accountName
        }
    }

    private func formatted(type: OATHType) -> String {
        switch type {
        case .totp:
            return "totp"
        case .hotp:
            return "hotp"
        }
    }
}

final class OATHURIEncoderTests: XCTestCase {
    func test_encode_totpUsesTOTPType() throws {
        let uri = OATHURI(type: .totp, accountName: "any")
        let sut = makeSUT()

        let encoded = try sut.encode(uri: uri)

        XCTAssertEqual(encoded, "otpauth://totp/any")
    }

    func test_encode_hotpUsesHOTPType() throws {
        let uri = OATHURI(type: .hotp, accountName: "any")
        let sut = makeSUT()

        let encoded = try sut.encode(uri: uri)

        XCTAssertEqual(encoded, "otpauth://hotp/any")
    }

    func test_encode_emptyLabelRendersNothingAfterSlash() throws {
        let uri = OATHURI(type: .hotp, accountName: "")
        let sut = makeSUT()

        let encoded = try sut.encode(uri: uri)

        XCTAssertEqual(encoded, "otpauth://hotp/")
    }

    func test_encode_accountNameOnlyRendersAsStandaloneLabel() throws {
        let uri = OATHURI(type: .hotp, accountName: "Account")
        let sut = makeSUT()

        let encoded = try sut.encode(uri: uri)

        XCTAssertEqual(encoded, "otpauth://hotp/Account")
    }

    func test_encode_labelIncludesIssuerAndAccountIssuerParameter() throws {
        let uri = OATHURI(type: .hotp, accountName: "Account", issuer: "Issuer")
        let sut = makeSUT()

        let encoded = try sut.encode(uri: uri)

        XCTAssertEqual(encoded, "otpauth://hotp/Issuer:Account?issuer=Issuer")
    }

    func test_encode_labelEncodesSpecialCharacters() throws {
        let uri = OATHURI(type: .hotp, accountName: "Account Name", issuer: "Issuer Name")
        let sut = makeSUT()

        let encoded = try sut.encode(uri: uri)

        XCTAssertEqual(encoded, "otpauth://hotp/Issuer%20Name:Account%20Name?issuer=Issuer%20Name")
    }

    // MARK: - Helpers

    private func makeSUT() -> OATHURIEncoder {
        OATHURIEncoder()
    }
}
