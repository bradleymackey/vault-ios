import Foundation

/// Common internal data used by OTP codes.
public struct OTPAuthCodeData: Equatable, Hashable {
    public var secret: OTPAuthSecret
    public var algorithm: OTPAuthAlgorithm
    public var digits: OTPAuthDigits
    public var accountName: String
    public var issuer: String?

    public init(
        secret: OTPAuthSecret,
        algorithm: OTPAuthAlgorithm = .default,
        digits: OTPAuthDigits = .default,
        accountName: String,
        issuer: String? = nil
    ) {
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.accountName = accountName
        self.issuer = issuer
    }
}

public struct OTPAuthSecret: Equatable, Hashable {
    public var data: Data
    /// The format that the secret was stored in.
    public var format: Format

    public enum Format: Equatable, Hashable {
        case base32
    }

    public init(data: Data, format: Format) {
        self.data = data
        self.format = format
    }

    public static func empty(_ format: Format = .base32) -> OTPAuthSecret {
        .init(data: Data(), format: format)
    }
}

public struct OTPAuthDigits: Equatable, Hashable, CustomStringConvertible {
    public var value: UInt16

    public init(value: UInt16) {
        self.value = value
    }

    public var description: String {
        "\(value)"
    }
}

public extension OTPAuthDigits {
    static var `default`: OTPAuthDigits { .init(value: 6) }
}

public enum OTPAuthAlgorithm: Equatable, Hashable {
    case sha1
    case sha256
    case sha512

    public static var `default`: OTPAuthAlgorithm { .sha1 }
}

public enum OTPAuthType: Equatable, Hashable {
    case totp(period: UInt64 = 30)
    case hotp(counter: UInt64 = 0)

    public enum Kind: Equatable {
        case totp, hotp
    }

    public var kind: Kind {
        switch self {
        case .totp:
            return .totp
        case .hotp:
            return .hotp
        }
    }
}
