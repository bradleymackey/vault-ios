import Foundation

public struct OTPAuthURIDecoder {
    public enum URIDecodingError: Error {
        case invalidURI
        case invalidScheme
        case invalidType
        case invalidLabel
        case invalidAlgorithm
    }

    public init() {}

    public func decode(string: String) throws -> OTPAuthCode {
        guard
            let url = URL(string: string),
            let scheme = url.scheme
        else {
            throw URIDecodingError.invalidURI
        }
        guard scheme == "otpauth" else {
            throw URIDecodingError.invalidScheme
        }
        let label = try decodeLabel(uri: url)
        return try OTPAuthCode(
            type: decodeType(uri: url),
            secret: decodeSecret(uri: url),
            algorithm: decodeAlgorithm(uri: url),
            digits: decodeDigits(uri: url),
            accountName: label.accountName,
            issuer: label.issuer
        )
    }
}

// MARK: - Helpers

extension OTPAuthURIDecoder {
    private func decodeSecret(uri: URL) throws -> OTPAuthSecret {
        guard let secret = uri.queryParameters["secret"], let data = base32DecodeToData(secret) else {
            return .empty(.base32)
        }
        return .init(data: data, format: .base32)
    }

    private func decodeDigits(uri: URL) throws -> OTPAuthDigits {
        guard let digits = uri.queryParameters["digits"], let value = Int(digits) else {
            return .default
        }
        return OTPAuthDigits(rawValue: value) ?? .default
    }

    private func decodeAlgorithm(uri: URL) throws -> OTPAuthAlgorithm {
        guard let algorithm = uri.queryParameters["algorithm"] else {
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
        var issuer = uri.queryParameters["issuer"]?.trimmingCharacters(in: .whitespacesAndNewlines)
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
            if let periodString = uri.queryParameters["period"], let period = UInt32(periodString) {
                return .totp(period: period)
            } else {
                return .totp()
            }
        case "hotp":
            if let counterStr = uri.queryParameters["counter"], let count = UInt32(counterStr) {
                return .hotp(counter: count)
            } else {
                return .hotp()
            }
        default:
            throw URIDecodingError.invalidType
        }
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
