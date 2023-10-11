import Foundation

/// Generic representation of any OTP code.
///
/// Useful when we want a non-type constrained model.
public struct GenericOTPAuthCode: Equatable, Hashable {
    public var type: OTPAuthType
    public var data: OTPAuthCodeData

    public init(
        type: OTPAuthType,
        data: OTPAuthCodeData
    ) {
        self.type = type
        self.data = data
    }
}
