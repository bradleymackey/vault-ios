import Foundation

public struct HOTPAuthCode: Sendable {
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

    public func renderCode() throws -> String {
        let renderer = OTPCodeRenderer()
        let generator = data.hotpGenerator()
        let code = try generator.code(counter: counter)
        return try renderer.render(code: code, digits: data.digits.value)
    }
}
