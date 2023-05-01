import Foundation

/// Encodes according to the spec for *otpauth*.
///
/// https://docs.yubico.com/yesdk/users-manual/application-oath/uri-string-format.html
public struct OTPAuthURIEncoder {
    enum URIEncodingError: Error {
        case badURIComponents
    }

    public init() {}

    public func encode(code: OTPAuthCode) throws -> OAuthURI {
        var components = URLComponents()
        components.scheme = "otpauth"
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
    private func makePath(code: OTPAuthCode) -> String {
        "/" + makeFormattedLabel(code: code)
    }

    private func makeQueryParameters(code: OTPAuthCode) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        queryItems.append(
            URLQueryItem(name: "secret", value: makeFormatted(secret: code.secret))
        )
        queryItems.append(
            URLQueryItem(name: "algorithm", value: formatted(algorithm: code.algorithm))
        )
        queryItems.append(
            URLQueryItem(name: "digits", value: "\(code.digits.rawValue)")
        )
        if let issuer = code.issuer {
            queryItems.append(
                URLQueryItem(name: "issuer", value: issuer)
            )
        }
        switch code.type {
        case let .totp(period):
            queryItems.append(
                URLQueryItem(name: "period", value: "\(period)")
            )
        case let .hotp(counter):
            queryItems.append(
                URLQueryItem(name: "counter", value: "\(counter)")
            )
        }
        return queryItems
    }

    private func makeFormatted(secret: OTPAuthSecret) -> String {
        base32Encode(secret.data)
    }

    private func makeFormattedLabel(code: OTPAuthCode) -> String {
        if let issuer = code.issuer {
            return "\(issuer):\(code.accountName)"
        } else {
            return code.accountName
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
