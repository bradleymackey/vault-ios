import Foundation

/// Decodes according to the spec for *otpauth*.
///
/// https://docs.yubico.com/yesdk/users-manual/application-oath/uri-string-format.html
public struct OTPAuthURIDecoder {
    public enum URIDecodingError: Error {
        case invalidScheme
        case invalidType
        case invalidLabel
        case invalidAlgorithm
    }

    public init() {}

    public func decode(uri: OTPAuthURI) throws -> OTPAuthCode {
        guard let scheme = uri.scheme, scheme == OTPAuthURI.otpAuthScheme else {
            throw URIDecodingError.invalidScheme
        }
        let label = try decodeLabel(uri: uri)
        return try OTPAuthCode(
            type: decodeType(uri: uri),
            secret: decodeSecret(uri: uri),
            algorithm: decodeAlgorithm(uri: uri),
            digits: decodeDigits(uri: uri),
            accountName: label.accountName,
            issuer: label.issuer
        )
    }
}

// MARK: - Helpers

extension OTPAuthURIDecoder {
    private func decodeSecret(uri: URL) throws -> OTPAuthSecret {
        guard let secret = uri.otpParameter(.secret), let data = base32DecodeToData(secret) else {
            return .empty(.base32)
        }
        return .init(data: data, format: .base32)
    }

    private func decodeDigits(uri: URL) throws -> OTPAuthDigits {
        guard let digits = uri.otpParameter(.digits), let value = Int(digits) else {
            return .default
        }
        return OTPAuthDigits(rawValue: value) ?? .default
    }

    private func decodeAlgorithm(uri: URL) throws -> OTPAuthAlgorithm {
        guard let algorithm = uri.otpParameter(.algorithm) else {
            return .default
        }
        switch algorithm {
        case "SHA1":
            return .sha1
        case "SHA256":
            return .sha256
        case "SHA512":
            return .sha512
        default:
            throw URIDecodingError.invalidAlgorithm
        }
    }

    private func decodeLabel(uri: URL) throws -> (accountName: String, issuer: String?) {
        guard uri.pathComponents.count > 1 else {
            throw URIDecodingError.invalidLabel
        }
        let label = uri.pathComponents[1]
        let parts = label.split(separator: ":")
        guard let accountName = parts.last?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw URIDecodingError.invalidLabel
        }
        var issuer = uri.otpParameter(.issuer)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if issuer == nil, parts.count > 1 {
            issuer = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return (String(accountName), issuer)
    }

    private func decodeType(uri: URL) throws -> OTPAuthType {
        guard let host = uri.host else {
            throw URIDecodingError.invalidType
        }
        switch host {
        case "totp":
            if let periodString = uri.otpParameter(.period), let period = UInt32(periodString) {
                return .totp(period: period)
            } else {
                return .totp()
            }
        case "hotp":
            if let counterStr = uri.otpParameter(.counter), let count = UInt32(counterStr) {
                return .hotp(counter: count)
            } else {
                return .hotp()
            }
        default:
            throw URIDecodingError.invalidType
        }
    }
}

extension URL {
    func otpParameter(_ parameter: OTPAuthURI.Parameter) -> String? {
        queryParameters[parameter.rawValue]
    }
}
