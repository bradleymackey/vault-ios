import Foundation

public typealias OTPAuthURI = URL

extension OTPAuthURI {
    /// The canonical URI scheme used for OTP auth code URIs.
    public static var otpAuthScheme: String {
        "otpauth"
    }
}

extension OTPAuthURI {
    /// A parameter value for OTPAuthURI
    enum Parameter: String {
        case secret
        case algorithm
        case digits
        case issuer
        case period
        case counter
    }
}
