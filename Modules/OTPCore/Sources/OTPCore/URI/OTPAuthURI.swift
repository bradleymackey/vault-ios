import Foundation

public typealias OTPAuthURI = URL

public extension OTPAuthURI {
    /// The canonical URI scheme used for OTP auth code URIs.
    static var otpAuthScheme: String {
        "otpauth"
    }
}
