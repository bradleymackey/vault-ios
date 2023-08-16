import Foundation
import OTPCore
import OTPFeed
import SwiftUI

public struct GenericOTPViewGenerator<TOTP, HOTP>: OTPViewGenerator where
    TOTP: OTPViewGenerator,
    TOTP.Code == TOTPAuthCode,
    HOTP: OTPViewGenerator,
    HOTP.Code == HOTPAuthCode
{
    public typealias Code = GenericOTPAuthCode

    public let totpGenerator: TOTP
    public let hotpGenerator: HOTP

    public init(totpGenerator: TOTP, hotpGenerator: HOTP) {
        self.totpGenerator = totpGenerator
        self.hotpGenerator = hotpGenerator
    }

    @ViewBuilder
    public func makeOTPView(id: UUID, code: Code, isEditing: Bool) -> some View {
        switch code.type {
        case let .totp(period):
            totpGenerator.makeOTPView(id: id, code: .init(period: period, code: code), isEditing: isEditing)
        case let .hotp(counter):
            hotpGenerator.makeOTPView(id: id, code: .init(counter: counter, code: code), isEditing: isEditing)
        }
    }
}
