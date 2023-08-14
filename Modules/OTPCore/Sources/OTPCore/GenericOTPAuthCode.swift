import Foundation

/// Generic representation of any OTP code.
///
/// Useful when we want a non-type constrained model.
public struct GenericOTPAuthCode: Equatable, OTPAuthCode {
    public var type: OTPAuthType
    public var secret: OTPAuthSecret
    public var algorithm: OTPAuthAlgorithm
    public var digits: OTPAuthDigits
    public var accountName: String
    public var issuer: String?

    public init(
        type: OTPAuthType,
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

    public func toGenericCode() -> GenericOTPAuthCode {
        self
    }
}
