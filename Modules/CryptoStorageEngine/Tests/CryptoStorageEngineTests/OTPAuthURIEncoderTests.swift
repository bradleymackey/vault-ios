import CryptoStorageEngine
import Foundation
import XCTest

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

    func encode(code: OTPAuthCode) throws -> URL {
        var components = URLComponents()
        components.scheme = "otpauth"
        components.host = formatted(type: code.type)
        components.path = "/" + formattedLabel(code: code)
        var queryItems = [URLQueryItem]()
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
        default:
            break
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

        expect(url: encoded, hasScheme: "otpauth")
    }

    func test_encodeType_totp() throws {
        let code = makeCode(type: .totp(), accountName: "")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(url: encoded, hasType: "totp")
        expect(url: encoded, hasPathComponents: ["/"])
    }

    func test_encodeType_hotp() throws {
        let code = makeCode(type: .hotp(), accountName: "")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(url: encoded, hasType: "hotp")
        expect(url: encoded, hasPathComponents: ["/"])
    }

    func test_encodeAccountName_includesInPath() throws {
        let code = makeCode(accountName: "Account")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(url: encoded, hasPathComponents: ["/", "Account"])
    }

    func test_encodeAccountName_includesInPathWithSpaces() throws {
        let code = makeCode(accountName: "Account Name")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(url: encoded, hasPathComponents: ["/", "Account Name"])
    }

    func test_encodeIssuer_includesInPathAndParameter() throws {
        let code = makeCode(accountName: "Account", issuer: "Issuer")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(url: encoded, hasPathComponents: ["/", "Issuer:Account"])
        expect(url: encoded, containsQueryParameter: ("issuer", "Issuer"))
    }

    func test_encodeIssuer_includesInPathAndParameterWithSpaces() throws {
        let code = makeCode(accountName: "Account Name", issuer: "Issuer Name")
        let sut = makeSUT()

        let encoded = try sut.encode(code: code)

        expect(url: encoded, hasPathComponents: ["/", "Issuer Name:Account Name"])
        expect(url: encoded, containsQueryParameter: ("issuer", "Issuer Name"))
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

            expect(url: encoded, containsQueryParameter: ("algorithm", string))
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

            expect(url: encoded, containsQueryParameter: ("digits", string))
        }
    }

    func test_encodePeriod_includesPeriodInParameters() throws {
        let samples: [UInt32] = [2, 100, 200, 2_000_000]
        for sample in samples {
            let code = makeCode(type: .totp(period: sample))
            let sut = makeSUT()

            let encoded = try sut.encode(code: code)

            expect(url: encoded, containsQueryParameter: ("period", "\(sample)"))
        }
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
        digits: OTPAuthDigits = .six
    ) -> OTPAuthCode {
        OTPAuthCode(
            type: type,
            secret: .init(data: Data(), format: .base32),
            algorithm: algorithm,
            digits: digits,
            accountName: accountName,
            issuer: issuer
        )
    }

    private func expect(url: URL, hasScheme scheme: String, file: StaticString = #filePath, line: UInt = #line) {
        let actual = url.scheme
        XCTAssertEqual(actual, scheme, file: file, line: line)
    }

    private func expect(url: URL, hasType type: String, file: StaticString = #filePath, line: UInt = #line) {
        let actual = url.host
        XCTAssertEqual(actual, type, file: file, line: line)
    }

    private func expect(
        url: URL,
        hasPathComponents pathComponents: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actual = url.pathComponents
        XCTAssertEqual(actual, pathComponents, file: file, line: line)
    }

    private func expect(
        url: URL,
        hasAllQueryParameters queryParamters: [String: String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actual = url.queryParameters
        XCTAssertEqual(actual, queryParamters, file: file, line: line)
    }

    private func expect(
        url: URL,
        containsQueryParameter parameter: (key: String, value: String),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
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
