import CryptoStorageEngine
import Foundation
import XCTest

typealias OAuthURI = URL

/// Encodes according to the spec for *otpauth*.
///
/// https://docs.yubico.com/yesdk/users-manual/application-oath/uri-string-format.html
struct OTPAuthURIEncoder {
    enum URIEncodingError: Error {
        case badURIComponents
    }

    private let digitFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    func encode(code: OTPAuthCode) throws -> OAuthURI {
        var components = URLComponents()
        components.scheme = "otpauth"
        components.host = formatted(type: code.type)
        components.path = "/" + formattedLabel(code: code)
        components.queryItems = makeQueryParameters(code: code)
        guard let url = components.url else {
            throw URIEncodingError.badURIComponents
        }
        return url
    }

    private func makeQueryParameters(code: OTPAuthCode) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        queryItems.append(
            URLQueryItem(name: "secret", value: formatted(secret: code.secret))
        )
        queryItems.append(
            URLQueryItem(name: "algorithm", value: formatted(algorithm: code.algorithm))
        )
        if let digits = formatted(digits: code.digits) {
            queryItems.append(
                URLQueryItem(name: "digits", value: digits)
            )
        }
        if let issuer = code.issuer {
            queryItems.append(
                URLQueryItem(name: "issuer", value: issuer)
            )
        }
        switch code.type {
        case let .totp(period):
            queryItems.append(
                URLQueryItem(name: "period", value: digitFormatter.string(from: period as NSNumber))
            )
        case let .hotp(counter):
            queryItems.append(
                URLQueryItem(name: "counter", value: digitFormatter.string(from: counter as NSNumber))
            )
        }
        return queryItems
    }

    private func formatted(secret: OTPAuthSecret) -> String {
        base32Encode(secret.data)
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

    private func formatted(digits: OTPAuthDigits) -> String? {
        let value = digits.rawValue
        return digitFormatter.string(from: value as NSNumber)
    }
}

final class OTPAuthURIEncoderTests: XCTestCase {
    func test_encodeScheme_isOtpauth() throws {
        let code = makeCode(type: .totp())
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(encoded, hasScheme: "otpauth")
    }

    func test_encodeType_totp() throws {
        let code = makeCode(type: .totp(), accountName: "")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(encoded, hasType: "totp")
        expect(encoded, hasPathComponents: ["/"])
    }

    func test_encodeType_hotp() throws {
        let code = makeCode(type: .hotp(), accountName: "")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(encoded, hasType: "hotp")
        expect(encoded, hasPathComponents: ["/"])
    }

    func test_encodeAccountName_includesInPath() throws {
        let code = makeCode(accountName: "Account")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(encoded, hasPathComponents: ["/", "Account"])
    }

    func test_encodeAccountName_includesInPathWithSpaces() throws {
        let code = makeCode(accountName: "Account Name")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(encoded, hasPathComponents: ["/", "Account Name"])
    }

    func test_encodeIssuer_includesInPathAndParameter() throws {
        let code = makeCode(accountName: "Account", issuer: "Issuer")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(encoded, hasPathComponents: ["/", "Issuer:Account"])
        expect(encoded, containsQueryParameter: ("issuer", "Issuer"))
    }

    func test_encodeIssuer_includesInPathAndParameterWithSpaces() throws {
        let code = makeCode(accountName: "Account Name", issuer: "Issuer Name")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(encoded, hasPathComponents: ["/", "Issuer Name:Account Name"])
        expect(encoded, containsQueryParameter: ("issuer", "Issuer Name"))
    }

    func test_encodeAlgorithm_includesInParameters() throws {
        let expected: [OTPAuthAlgorithm: String] = [
            .sha1: "SHA1",
            .sha256: "SHA256",
            .sha512: "SHA512",
        ]
        for (algorithm, string) in expected {
            let code = makeCode(algorithm: algorithm)
            let sut = makeSUT()

            let encoded = try sut.encode(code: code)

            expect(encoded, containsQueryParameter: ("algorithm", string))
        }
    }

    func test_encodeDigits_includesInParameters() throws {
        let expected: [OTPAuthDigits: String] = [
            .six: "6",
            .seven: "7",
            .eight: "8",
        ]

        for (digits, string) in expected {
            let code = makeCode(digits: digits)
            let sut = makeSUT()

            let encoded = try sut.encode(code: code)

            expect(encoded, containsQueryParameter: ("digits", string))
        }
    }

    func test_encodePeriod_includesPeriodInParameters() throws {
        let samples: [UInt32] = [2, 100, 200, 2_000_000]
        for sample in samples {
            let code = makeCode(type: .totp(period: sample))
            let sut = makeSUT()

            let encoded = try sut.encode(code: code)

            expect(encoded, containsQueryParameter: ("period", "\(sample)"))
            expect(encoded, doesNotContainQueryParameter: "counter")
        }
    }

    func test_encodeCounter_includesCounterInParameters() throws {
        let samples: [UInt32] = [2, 100, 200, 2_000_000]
        for sample in samples {
            let code = makeCode(type: .hotp(counter: sample))
            let sut = makeSUT()

            let encoded = try sut.encode(code: code)

            expect(encoded, containsQueryParameter: ("counter", "\(sample)"))
            expect(encoded, doesNotContainQueryParameter: "period")
        }
    }

    func test_encodeSecret_includesEmptySecret() throws {
        let secret = OTPAuthSecret(data: Data(), format: .base32)
        let code = makeCode(secret: secret)
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(encoded, containsQueryParameter: ("secret", ""))
    }

    func test_encodeSecret_includesSecretWithData() throws {
        let data = Data(repeating: 0xAA, count: 5)
        let secret = OTPAuthSecret(data: data, format: .base32)
        let code = makeCode(secret: secret)
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(encoded, containsQueryParameter: ("secret", "VKVKVKVK"))
    }

    func test_encodeSecret_includesSecretWithDataAndPadding() throws {
        let bytes: [UInt8] = [0xAB, 0x21, 0x12, 0x43, 0xFF, 0xEE, 0xDD, 0x00]
        let secret = OTPAuthSecret(data: Data(bytes), format: .base32)
        let code = makeCode(secret: secret)
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(encoded, containsQueryParameter: ("secret", "VMQREQ7753OQA==="))
    }

    // MARK: - Helpers

    private func makeSUT() -> OTPAuthURIEncoder {
        OTPAuthURIEncoder()
    }

    private func makeCode(
        type: OTPAuthType = .totp(),
        accountName: String = "any",
        issuer: String? = nil,
        algorithm: OTPAuthAlgorithm = .sha1,
        digits: OTPAuthDigits = .six,
        secret: OTPAuthSecret = .init(data: Data(), format: .base32)
    ) -> OTPAuthCode {
        OTPAuthCode(
            type: type,
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            accountName: accountName,
            issuer: issuer
        )
    }

    private func expect(_ uri: OAuthURI, hasScheme scheme: String, file: StaticString = #filePath, line: UInt = #line) {
        let actual = uri.scheme
        XCTAssertEqual(actual, scheme, file: file, line: line)
    }

    private func expect(_ uri: OAuthURI, hasType type: String, file: StaticString = #filePath, line: UInt = #line) {
        let actual = uri.host
        XCTAssertEqual(actual, type, file: file, line: line)
    }

    private func expect(
        _ uri: OAuthURI,
        hasPathComponents pathComponents: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actual = uri.pathComponents
        XCTAssertEqual(actual, pathComponents, file: file, line: line)
    }

    private func expect(
        _ uri: OAuthURI,
        hasAllQueryParameters queryParamters: [String: String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actual = uri.queryParameters
        XCTAssertEqual(actual, queryParamters, file: file, line: line)
    }

    private func expect(
        _ uri: OAuthURI,
        containsQueryParameter parameter: (key: String, value: String),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actual = uri.queryParameters ?? [:]
        let actualValue = actual[parameter.key]
        XCTAssertEqual(actualValue, parameter.value, file: file, line: line)
    }

    private func expect(
        _ uri: OAuthURI,
        doesNotContainQueryParameter parameter: String,
        file _: StaticString = #filePath,
        line _: UInt = #line
    ) {
        let actual = uri.queryParameters ?? [:]
        let keys = actual.keys
        XCTAssertFalse(keys.contains(where: { $0 == parameter }))
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
