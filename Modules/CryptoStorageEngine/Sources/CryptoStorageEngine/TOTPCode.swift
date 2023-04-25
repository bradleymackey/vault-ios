import Foundation

public struct TOTPCode {
    public var secret: TOTPSecret
    public var algorithm: TOTPAlgorithm
    public var digits: TOTPDigits
    public var label: String
    public var issuer: String?
    public var period: UInt = 30

    public init(
        secret: TOTPSecret,
        algorithm: TOTPAlgorithm = .sha1,
        digits: TOTPDigits = .six,
        label: String,
        issuer: String? = nil,
        period: UInt = 30
    ) {
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.label = label
        self.issuer = issuer
        self.period = period
    }
}

public struct TOTPSecret {
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

public enum TOTPDigits: Int {
    case six = 6
    case seven = 7
    case eight = 8
}

public enum TOTPAlgorithm: String {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
}
