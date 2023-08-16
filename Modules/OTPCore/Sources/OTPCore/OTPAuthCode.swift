import Foundation

public protocol OTPAuthCode {
    var secret: OTPAuthSecret { get }
    var algorithm: OTPAuthAlgorithm { get }
    var digits: OTPAuthDigits { get }
    var accountName: String { get }
    var issuer: String? { get }

    func toGenericCode() -> GenericOTPAuthCode
}

public struct TOTPAuthCode: OTPAuthCode {
    public var period: UInt64
    public var secret: OTPAuthSecret
    public var algorithm: OTPAuthAlgorithm
    public var digits: OTPAuthDigits
    public var accountName: String
    public var issuer: String?

    public init(
        period: UInt64 = 30,
        secret: OTPAuthSecret,
        algorithm: OTPAuthAlgorithm,
        digits: OTPAuthDigits,
        accountName: String,
        issuer: String? = nil
    ) {
        self.period = period
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.accountName = accountName
        self.issuer = issuer
    }

    public init(period: UInt64, code: any OTPAuthCode) {
        self.period = period
        secret = code.secret
        algorithm = code.algorithm
        digits = code.digits
        accountName = code.accountName
        issuer = code.issuer
    }

    public init?(generic: GenericOTPAuthCode) {
        guard case let .totp(period) = generic.type else {
            return nil
        }
        self.period = period
        secret = generic.secret
        algorithm = generic.algorithm
        digits = generic.digits
        accountName = generic.accountName
        issuer = generic.issuer
    }

    public func toGenericCode() -> GenericOTPAuthCode {
        GenericOTPAuthCode(
            type: .totp(period: period),
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            accountName: accountName,
            issuer: issuer
        )
    }
}

public struct HOTPAuthCode: OTPAuthCode {
    public var counter: UInt64 = 0
    public var secret: OTPAuthSecret
    public var algorithm: OTPAuthAlgorithm
    public var digits: OTPAuthDigits
    public var accountName: String
    public var issuer: String?

    public init(
        counter: UInt64 = 0,
        secret: OTPAuthSecret,
        algorithm: OTPAuthAlgorithm,
        digits: OTPAuthDigits,
        accountName: String,
        issuer: String? = nil
    ) {
        self.counter = counter
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.accountName = accountName
        self.issuer = issuer
    }

    public init(counter: UInt64, code: any OTPAuthCode) {
        self.counter = counter
        secret = code.secret
        algorithm = code.algorithm
        digits = code.digits
        accountName = code.accountName
        issuer = code.issuer
    }

    public init?(generic: GenericOTPAuthCode) {
        guard case let .hotp(counter) = generic.type else {
            return nil
        }
        self.counter = counter
        secret = generic.secret
        algorithm = generic.algorithm
        digits = generic.digits
        accountName = generic.accountName
        issuer = generic.issuer
    }

    public func toGenericCode() -> GenericOTPAuthCode {
        GenericOTPAuthCode(
            type: .hotp(counter: counter),
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            accountName: accountName,
            issuer: issuer
        )
    }
}

public struct OTPAuthSecret: Equatable {
    public var data: Data
    /// The format that the secret was stored in.
    public var format: Format

    public enum Format: Equatable {
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

public enum OTPAuthDigits: Int, Equatable {
    case six = 6
    case seven = 7
    case eight = 8

    public static var `default`: OTPAuthDigits { .six }
}

public enum OTPAuthAlgorithm: Equatable {
    case sha1
    case sha256
    case sha512

    public static var `default`: OTPAuthAlgorithm { .sha1 }
}

public enum OTPAuthType: Equatable {
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
