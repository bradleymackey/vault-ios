import Foundation
import Testing
import VaultCore

struct OTPAuthURIEncoderTests {
    let sut = OTPAuthURIEncoder()

    @Test
    func test_encodeScheme_isOtpauth() throws {
        let code = makeCode(type: .totp())
        let encoded = try sut.encode(code: code)

        expect(encoded, hasScheme: "otpauth")
    }

    @Test
    func encodeType_totp() throws {
        let code = makeCode(type: .totp(), accountName: "")

        let encoded = try sut.encode(code: code)

        expect(encoded, hasType: "totp")
        expect(encoded, hasPathComponents: ["/"])
    }

    @Test
    func encodeType_hotp() throws {
        let code = makeCode(type: .hotp(), accountName: "")

        let encoded = try sut.encode(code: code)

        expect(encoded, hasType: "hotp")
        expect(encoded, hasPathComponents: ["/"])
    }

    @Test
    func encodeAccountName_includesInPath() throws {
        let code = makeCode(accountName: "Account")

        let encoded = try sut.encode(code: code)

        expect(encoded, hasPathComponents: ["/", "Account"])
    }

    @Test
    func encodeAccountName_includesInPathWithSpaces() throws {
        let code = makeCode(accountName: "Account Name")

        let encoded = try sut.encode(code: code)

        expect(encoded, hasPathComponents: ["/", "Account Name"])
    }

    @Test
    func encodeIssuer_includesInPathAndParameter() throws {
        let code = makeCode(accountName: "Account", issuer: "Issuer")

        let encoded = try sut.encode(code: code)

        expect(encoded, hasPathComponents: ["/", "Issuer:Account"])
        expect(encoded, containsQueryParameter: ("issuer", "Issuer"))
    }

    @Test
    func encodeIssuer_includesInPathAndParameterWithSpaces() throws {
        let code = makeCode(accountName: "Account Name", issuer: "Issuer Name")

        let encoded = try sut.encode(code: code)

        expect(encoded, hasPathComponents: ["/", "Issuer Name:Account Name"])
        expect(encoded, containsQueryParameter: ("issuer", "Issuer Name"))
    }

    @Test(arguments: [
        (.sha1, "SHA1"),
        (.sha256, "SHA256"),
        (.sha512, "SHA512"),
    ] as [(OTPAuthAlgorithm, String)])
    func encodeAlgorithm_includesInParameters(algorithm: OTPAuthAlgorithm, string: String) throws {
        let code = makeCode(algorithm: algorithm)

        let encoded = try sut.encode(code: code)

        expect(encoded, containsQueryParameter: ("algorithm", string))
    }

    @Test(arguments: [
        (6, "6"),
        (7, "7"),
        (8, "8"),
        (120, "120"),
    ] as [(OTPAuthDigits, String)])
    func encodeDigits_includesInParameters(digits: OTPAuthDigits, string: String) throws {
        let code = makeCode(digits: digits)

        let encoded = try sut.encode(code: code)

        expect(encoded, containsQueryParameter: ("digits", string))
    }

    @Test(arguments: [
        2,
        100,
        200,
        2_000_000,
    ])
    func encodePeriod_includesPeriodInParameters(period: UInt64) throws {
        let code = makeCode(type: .totp(period: period))

        let encoded = try sut.encode(code: code)

        expect(encoded, containsQueryParameter: ("period", "\(period)"))
        expect(encoded, doesNotContainQueryParameter: "counter")
    }

    @Test(arguments: [
        2,
        100,
        200,
        2_000_000,
    ])
    func encodeCounter_includesCounterInParameters(counter: UInt64) throws {
        let code = makeCode(type: .hotp(counter: counter))

        let encoded = try sut.encode(code: code)

        expect(encoded, containsQueryParameter: ("counter", "\(counter)"))
        expect(encoded, doesNotContainQueryParameter: "period")
    }

    @Test
    func encodeSecret_includesEmptySecret() throws {
        let secret = OTPAuthSecret(data: Data(), format: .base32)
        let code = makeCode(secret: secret)
        let encoded = try sut.encode(code: code)

        expect(encoded, containsQueryParameter: ("secret", ""))
    }

    @Test
    func encodeSecret_includesSecretWithData() throws {
        let data = Data(repeating: 0xAA, count: 5)
        let secret = OTPAuthSecret(data: data, format: .base32)
        let code = makeCode(secret: secret)
        let encoded = try sut.encode(code: code)

        expect(encoded, containsQueryParameter: ("secret", "VKVKVKVK"))
    }

    @Test
    func encodeSecret_includesSecretWithDataAndPadding() throws {
        let bytes: [UInt8] = [0xAB, 0x21, 0x12, 0x43, 0xFF, 0xEE, 0xDD, 0x00]
        let secret = OTPAuthSecret(data: Data(bytes), format: .base32)
        let code = makeCode(secret: secret)
        let encoded = try sut.encode(code: code)

        expect(encoded, containsQueryParameter: ("secret", "VMQREQ7753OQA==="))
    }

    @Test
    func encode_encodesAllParameters() throws {
        let data = Data(repeating: 0xAA, count: 5)
        let secret = OTPAuthSecret(data: data, format: .base32)
        let code = makeCode(
            type: .totp(period: 69),
            accountName: "Account",
            issuer: "Issuer",
            algorithm: .sha512,
            digits: .init(value: 8),
            secret: secret
        )

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
}

// MARK: - Helpers

extension OTPAuthURIEncoderTests {
    private func makeCode(
        type: OTPAuthType = .totp(),
        accountName: String = "any",
        issuer: String = "",
        algorithm: OTPAuthAlgorithm = .default,
        digits: OTPAuthDigits = .default,
        secret: OTPAuthSecret = .init(data: Data(), format: .base32)
    ) -> OTPAuthCode {
        OTPAuthCode(
            type: type,
            data: .init(
                secret: secret,
                algorithm: algorithm,
                digits: digits,
                accountName: accountName,
                issuer: issuer
            )
        )
    }

    private func expect(
        _ uri: OTPAuthURI,
        hasScheme scheme: String,
        sourceLocation: SourceLocation = .__here()
    ) {
        let actual = uri.scheme
        #expect(actual == scheme, sourceLocation: sourceLocation)
    }

    private func expect(_ uri: OTPAuthURI, hasType type: String, sourceLocation: SourceLocation = .__here()) {
        let actual = uri.host
        #expect(actual == type, sourceLocation: sourceLocation)
    }

    private func expect(
        _ uri: OTPAuthURI,
        hasPathComponents pathComponents: [String],
        sourceLocation: SourceLocation = .__here()
    ) {
        #expect(uri.pathComponents == pathComponents, sourceLocation: sourceLocation)
    }

    private func expect(
        _ uri: OTPAuthURI,
        hasAllQueryParameters queryParamters: [String: String],
        sourceLocation: SourceLocation = .__here()
    ) {
        #expect(uri.queryParameters == queryParamters, sourceLocation: sourceLocation)
    }

    private func expect(
        _ uri: OTPAuthURI,
        containsQueryParameter parameter: (key: String, value: String),
        sourceLocation: SourceLocation = .__here()
    ) {
        let actualValue = uri.queryParameters[parameter.key]
        #expect(actualValue == parameter.value, sourceLocation: sourceLocation)
    }

    private func expect(
        _ uri: OTPAuthURI,
        doesNotContainQueryParameter parameter: String,
        sourceLocation: SourceLocation = .__here()
    ) {
        let keys = uri.queryParameters.keys
        #expect(keys.contains(where: { $0 == parameter }) == false, sourceLocation: sourceLocation)
    }
}

extension URL {
    fileprivate var queryParameters: [String: String] {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return [:] }
        return queryItems.reduce(into: [String: String]()) { result, item in
            result[item.name] = item.value
        }
    }
}
