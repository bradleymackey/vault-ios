import Foundation

public struct TOTPAuthCode: Sendable {
    public var period: UInt64
    public var data: OTPAuthCodeData

    public init(
        period: UInt64 = 30,
        data: OTPAuthCodeData
    ) {
        self.period = period
        self.data = data
    }

    public func toGenericCode() -> OTPAuthCode {
        OTPAuthCode(
            type: .totp(period: period),
            data: data
        )
    }
}
