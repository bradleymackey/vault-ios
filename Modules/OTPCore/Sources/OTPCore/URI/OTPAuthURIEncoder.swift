import Foundation

/// Encodes according to the spec for *otpauth*.
///
/// https://docs.yubico.com/yesdk/users-manual/application-oath/uri-string-format.html
public struct OTPAuthURIEncoder {
    enum URIEncodingError: Error {
        case badURIComponents
    }

    public init() {}

    public func encode(code: GenericOTPAuthCode) throws -> OTPAuthURI {
        var components = URLComponents()
        components.scheme = OTPAuthURI.otpAuthScheme
        components.host = makeFormatted(type: code.type)
        components.path = makePath(code: code)
        components.queryItems = makeQueryParameters(code: code)
        guard let url = components.url else {
            throw URIEncodingError.badURIComponents
        }
        return url
    }
}

// MARK: - Helpers

extension OTPAuthURIEncoder {
    private func makePath(code: GenericOTPAuthCode) -> String {
        "/" + makeFormattedLabel(code: code)
    }

    private func makeQueryParameters(code: GenericOTPAuthCode) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        queryItems.append(
            .otpAuth(.secret, value: makeFormatted(secret: code.data.secret))
        )
        queryItems.append(
            .otpAuth(.algorithm, value: formatted(algorithm: code.data.algorithm))
        )
        queryItems.append(
            .otpAuth(.digits, value: "\(code.data.digits.value)")
        )
        if let issuer = code.data.issuer {
            queryItems.append(
                .otpAuth(.issuer, value: issuer)
            )
        }
        switch code.type {
        case let .totp(period):
            queryItems.append(
                .otpAuth(.period, value: "\(period)")
            )
        case let .hotp(counter):
            queryItems.append(
                .otpAuth(.counter, value: "\(counter)")
            )
        }
        return queryItems
    }

    private func makeFormatted(secret: OTPAuthSecret) -> String {
        base32Encode(secret.data)
    }

    private func makeFormattedLabel(code: GenericOTPAuthCode) -> String {
        if let issuer = code.data.issuer {
            return "\(issuer):\(code.data.accountName)"
        } else {
            return code.data.accountName
        }
    }

    private func makeFormatted(type: OTPAuthType) -> String {
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

extension URLQueryItem {
    static func otpAuth(_ parameter: OTPAuthURI.Parameter, value: String) -> URLQueryItem {
        URLQueryItem(name: parameter.rawValue, value: value)
    }
}
