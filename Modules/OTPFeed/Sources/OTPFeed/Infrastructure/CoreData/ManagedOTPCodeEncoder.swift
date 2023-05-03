import CoreData
import Foundation
import OTPCore

struct ManagedOTPCodeEncoder {
    let context: NSManagedObjectContext
    func encode(code: OTPAuthCode) -> ManagedOTPCode {
        let managed = ManagedOTPCode(context: context)
        managed.digits = code.digits.rawValue as NSNumber
        return managed
    }
}
