import Foundation
import OTPCore
import XCTest

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

    func test_encode_encodesAllParameters() throws {
        let data = Data(repeating: 0xAA, count: 5)
        let secret = OTPAuthSecret(data: data, format: .base32)
        let code = makeCode(
            type: .totp(period: 69),
            accountName: "Account",
            issuer: "Issuer",
            algorithm: .sha512,
            digits: .eight,
            secret: secret
        )

        let sut = makeSUT()

        let encoded = try sut.encode(code: code)
        expect(encoded, hasScheme: "otpauth")
        expect(encoded, hasType: "totp")
        expect(encoded, hasPathComponents: ["/", "Issuer:Account"])
        expect(encoded, hasAllQueryParameters: [
            "issuer": "Issuer",
            "digits": "8",
            "secret": "VKVKVKVK",
            "period": "69",
            "algorithm": "SHA512",
        ])
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

    private func expect(
        _ uri: OTPAuthURI,
        hasScheme scheme: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actual = uri.scheme
        XCTAssertEqual(actual, scheme, file: file, line: line)
    }

    private func expect(_ uri: OTPAuthURI, hasType type: String, file: StaticString = #filePath, line: UInt = #line) {
        let actual = uri.host
        XCTAssertEqual(actual, type, file: file, line: line)
    }

    private func expect(
        _ uri: OTPAuthURI,
        hasPathComponents pathComponents: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(uri.pathComponents, pathComponents, file: file, line: line)
    }

    private func expect(
        _ uri: OTPAuthURI,
        hasAllQueryParameters queryParamters: [String: String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(uri.queryParameters, queryParamters, file: file, line: line)
    }

    private func expect(
        _ uri: OTPAuthURI,
        containsQueryParameter parameter: (key: String, value: String),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actualValue = uri.queryParameters[parameter.key]
        XCTAssertEqual(actualValue, parameter.value, file: file, line: line)
    }

    private func expect(
        _ uri: OTPAuthURI,
        doesNotContainQueryParameter parameter: String,
        file _: StaticString = #filePath,
        line _: UInt = #line
    ) {
        let keys = uri.queryParameters.keys
        XCTAssertFalse(keys.contains(where: { $0 == parameter }))
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
