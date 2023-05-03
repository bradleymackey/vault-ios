import CoreData
import Foundation
import OTPCore

struct ManagedOTPCodeEncoder {
    let context: NSManagedObjectContext
    func encode(code: OTPAuthCode) -> ManagedOTPCode {
        let managed = ManagedOTPCode(context: context)
        managed.id = UUID()
        managed.digits = code.digits.rawValue as NSNumber
        managed.authType = authTypeString(authType: code.type)
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
}
