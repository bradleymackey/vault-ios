import Foundation

public struct HOTPAuthCode {
    public var counter: UInt64 = 0
    public var data: OTPAuthCodeData

    public init(
        counter: UInt64 = 0,
        data: OTPAuthCodeData
    ) {
        self.counter = counter
        self.data = data
    }

    public func toGenericCode() -> OTPAuthCode {
        OTPAuthCode(
            type: .hotp(counter: counter),
            data: data
        )
    }
}
