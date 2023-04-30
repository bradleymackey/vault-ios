import Foundation

public struct OTPAuthCode {
    public var type: OTPAuthType
    public var secret: OTPAuthSecret
    public var algorithm: OTPAuthAlgorithm
    public var digits: OTPAuthDigits
    public var accountName: String
    public var issuer: String?
    public var period: UInt = 30

    public init(
        type: OTPAuthType = .totp,
        secret: OTPAuthSecret,
        algorithm: OTPAuthAlgorithm = .sha1,
        digits: OTPAuthDigits = .six,
        accountName: String,
        issuer: String? = nil,
        period: UInt = 30
    ) {
        self.type = type
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.accountName = accountName
        self.issuer = issuer
        self.period = period
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

public enum OTPAuthAlgorithm: String {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
}

public enum OTPAuthType {
    case totp
    case hotp
}
