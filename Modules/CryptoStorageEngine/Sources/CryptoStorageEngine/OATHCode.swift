import Foundation

public struct OATHCode {
    public var secret: OATHSecret
    public var algorithm: OATHAlgorithm
    public var digits: OATHDigits
    public var accountName: String
    public var issuer: String?
    public var period: UInt = 30

    public init(
        secret: OATHSecret,
        algorithm: OATHAlgorithm = .sha1,
        digits: OATHDigits = .six,
        accountName: String,
        issuer: String? = nil,
        period: UInt = 30
    ) {
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.accountName = accountName
        self.issuer = issuer
        self.period = period
    }
}

public struct OATHSecret {
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

public enum OATHDigits: Int {
    case six = 6
    case seven = 7
    case eight = 8
}

public enum OATHAlgorithm: String {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
}
