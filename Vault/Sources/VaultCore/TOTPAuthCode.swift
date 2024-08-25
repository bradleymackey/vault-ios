import CryptoEngine
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

    public func renderCode(epochSeconds: UInt64) throws -> String {
        let renderer = OTPCodeRenderer()
        let generator = TOTPGenerator(generator: data.hotpGenerator())
        let code = try generator.code(epochSeconds: epochSeconds)
        return try renderer.render(code: code, digits: data.digits.value)
    }
}
