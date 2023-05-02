import Foundation

public struct OTPAuthCode {
    public var type: OTPAuthType
    public var secret: OTPAuthSecret
    public var algorithm: OTPAuthAlgorithm
    public var digits: OTPAuthDigits
    public var accountName: String
    public var issuer: String?

    public init(
        type: OTPAuthType = .totp(period: 30),
        secret: OTPAuthSecret,
        algorithm: OTPAuthAlgorithm = .sha1,
        digits: OTPAuthDigits = .six,
        accountName: String,
        issuer: String? = nil
    ) {
        self.type = type
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.accountName = accountName
        self.issuer = issuer
    }
}

public struct OTPAuthSecret {
    public var data: Data
    /// The format that the secret was stored in.
    public var format: Format

    public enum Format {
        case base32
    }

    public init(data: Data, format: Format) {
        self.data = data
        self.format = format
    }
}

public enum OTPAuthDigits: Int {
    case six = 6
    case seven = 7
    case eight = 8
}

public enum OTPAuthAlgorithm {
    case sha1
    case sha256
    case sha512
}

public enum OTPAuthType {
    case totp(period: UInt32 = 30)
    case hotp(counter: UInt32 = 0)

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
