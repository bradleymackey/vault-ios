import CoreData
import Foundation
import OTPCore

struct ManagedOTPCodeEncoder {
    let context: NSManagedObjectContext
    func encode(code: OTPAuthCode) -> ManagedOTPCode {
        let managed = ManagedOTPCode(context: context)
        managed.id = UUID()
        managed.digits = code.digits.rawValue as NSNumber
        managed.accountName = code.accountName
        managed.issuer = code.issuer
        managed.authType = authTypeString(authType: code.type)
        managed.period = authTypePeriod(authType: code.type)
        managed.counter = authTypeCounter(authType: code.type)
        return managed
    }

    private func authTypeString(authType: OTPAuthType) -> String {
        switch authType {
        case .totp:
            return "totp"
        case .hotp:
            return "hotp"
        }
    }

    private func authTypePeriod(authType: OTPAuthType) -> NSNumber? {
        switch authType {
        case let .totp(period):
            return period as NSNumber
        case .hotp:
            return nil
        }
    }

    private func authTypeCounter(authType: OTPAuthType) -> NSNumber? {
        switch authType {
        case .totp:
            return nil
        case let .hotp(counter):
            return counter as NSNumber
        }
    }
}
