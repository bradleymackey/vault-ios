import CoreData
import Foundation
import OTPCore

struct ManagedOTPCodeEncoder {
    let context: NSManagedObjectContext
    let currentDate: () -> Date

    init(context: NSManagedObjectContext, currentDate: @escaping () -> Date = { Date() }) {
        self.context = context
        self.currentDate = currentDate
    }

    func encode(code value: StoredOTPCode.Write, into existing: ManagedOTPCode? = nil) -> ManagedOTPCode {
        let managed = existing ?? ManagedOTPCode(context: context)
        managed.id = existing?.id ?? UUID()
        managed.digits = value.code.digits.rawValue as NSNumber
        managed.accountName = value.code.accountName
        managed.issuer = value.code.issuer
        managed.authType = authTypeString(authType: value.code.type)
        managed.period = authTypePeriod(authType: value.code.type)
        managed.counter = authTypeCounter(authType: value.code.type)
        managed.algorithm = encoded(algorithm: value.code.algorithm)
        managed.secretFormat = encoded(secretFormat: value.code.secret.format)
        managed.secretData = value.code.secret.data
        managed.createdDate = existing?.createdDate ?? currentDate()
        managed.updatedDate = currentDate()
        managed.userDescription = value.userDescription
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

    private func encoded(algorithm: OTPAuthAlgorithm) -> String {
        switch algorithm {
        case .sha1:
            return "SHA1"
        case .sha256:
            return "SHA256"
        case .sha512:
            return "SHA512"
        }
    }

    private func encoded(secretFormat: OTPAuthSecret.Format) -> String {
        switch secretFormat {
        case .base32:
            return "BASE_32"
        }
    }
}
