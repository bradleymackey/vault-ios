import CryptoStorageEngine
import Foundation
import XCTest

struct OTPAuthURIEncoder {
    enum URIEncodingError: Error {
        case badURIComponents
    }

    func encode(code: OTPAuthCode) throws -> URL {
        var components = URLComponents()
        components.scheme = "otpauth"
        components.host = formatted(type: code.type)
        components.path = "/" + formattedLabel(code: code)
        var queryItems = [URLQueryItem]()
        queryItems.append(
            URLQueryItem(name: "algorithm", value: formatted(algorithm: code.algorithm))
        )
        if let issuer = code.issuer {
            queryItems.append(
                URLQueryItem(name: "issuer", value: issuer)
            )
        }
        components.queryItems = queryItems
        guard let url = components.url else {
            throw URIEncodingError.badURIComponents
        }
        return url
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

    private func formatted(algorithm: OTPAuthAlgorithm) -> String {
        switch algorithm {
        case .sha1:
            return "SHA1"
        case .sha256:
            return "SHA256"
        case .sha512:
            return "SHA512"
        }
    }
}

final class OTPAuthURIEncoderTests: XCTestCase {
    func test_encode_otpauthscheme() throws {
        let code = makeCode(type: .totp)
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(url: encoded, hasScheme: "otpauth")
    }

    func test_encode_totpUsesTOTPType() throws {
        let code = makeCode(type: .totp, accountName: "")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(url: encoded, hasType: "totp")
        expect(url: encoded, hasPathComponents: ["/"])
    }

    func test_encode_hotpUsesHOTPType() throws {
        let code = makeCode(type: .hotp, accountName: "")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(url: encoded, hasType: "hotp")
        expect(url: encoded, hasPathComponents: ["/"])
    }

    func test_encode_accountNameOnlyRendersAsStandaloneLabel() throws {
        let code = makeCode(accountName: "Account")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(url: encoded, hasPathComponents: ["/", "Account"])
    }

    func test_encode_labelIncludesIssuerAndAccountIssuerParameter() throws {
        let code = makeCode(accountName: "Account", issuer: "Issuer")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(url: encoded, hasPathComponents: ["/", "Issuer:Account"])
        expect(url: encoded, containsQueryParameter: ("issuer", "Issuer"))
    }

    func test_encode_labelEncodesIssuerAndAccountNamesWithSpaces() throws {
        let code = makeCode(accountName: "Account Name", issuer: "Issuer Name")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(url: encoded, hasPathComponents: ["/", "Issuer Name:Account Name"])
        expect(url: encoded, containsQueryParameter: ("issuer", "Issuer Name"))
    }

    func test_encode_encodesAlgorithmTypesCorrectly() throws {
        let expected: [OTPAuthAlgorithm: String] = [
            .sha1: "SHA1",
            .sha256: "SHA256",
            .sha512: "SHA512",
        ]
        for (algorithm, string) in expected {
            let code = makeCode(algorithm: algorithm)
            let sut = makeSUT()

            let encoded = try sut.encode(code: code)

            expect(url: encoded, containsQueryParameter: ("algorithm", string))
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> OTPAuthURIEncoder {
        OTPAuthURIEncoder()
    }

    private func makeCode(type: OTPAuthType = .totp, accountName: String = "any", issuer: String? = nil, algorithm: OTPAuthAlgorithm = .sha1) -> OTPAuthCode {
        OTPAuthCode(type: type, secret: .init(data: Data(), format: .base32), algorithm: algorithm, accountName: accountName, issuer: issuer)
    }

    private func expect(url: URL, hasScheme scheme: String, file: StaticString = #filePath, line: UInt = #line) {
        let actual = url.scheme
        XCTAssertEqual(actual, scheme, file: file, line: line)
    }

    private func expect(url: URL, hasType type: String, file: StaticString = #filePath, line: UInt = #line) {
        let actual = url.host
        XCTAssertEqual(actual, type, file: file, line: line)
    }

    private func expect(url: URL, hasPathComponents pathComponents: [String], file: StaticString = #filePath, line: UInt = #line) {
        let actual = url.pathComponents
        XCTAssertEqual(actual, pathComponents, file: file, line: line)
    }

    private func expect(url: URL, hasAllQueryParameters queryParamters: [String: String], file: StaticString = #filePath, line: UInt = #line) {
        let actual = url.queryParameters
        XCTAssertEqual(actual, queryParamters, file: file, line: line)
    }

    private func expect(url: URL, containsQueryParameter parameter: (key: String, value: String), file: StaticString = #filePath, line: UInt = #line) {
        let actual = url.queryParameters ?? [:]
        XCTAssertTrue(actual.contains { test in
            test.key == parameter.key && test.value == parameter.value
        }, file: file, line: line)
    }
}

private extension URL {
    var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { result, item in
            result[item.name] = item.value
        }
    }
}
