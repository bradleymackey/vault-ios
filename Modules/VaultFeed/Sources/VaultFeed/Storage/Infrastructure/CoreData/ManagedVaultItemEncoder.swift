import CoreData
import Foundation
import VaultCore

struct ManagedVaultItemEncoder {
    let context: NSManagedObjectContext
    let currentDate: () -> Date

    init(context: NSManagedObjectContext, currentDate: @escaping () -> Date = { Date() }) {
        self.context = context
        self.currentDate = currentDate
    }

    func encode(code value: StoredVaultItem.Write, into existing: ManagedVaultItem? = nil) -> ManagedVaultItem {
        let managed = existing ?? ManagedVaultItem(context: context)
        managed.id = existing?.id ?? UUID()
        managed.createdDate = existing?.createdDate ?? currentDate()
        managed.updatedDate = currentDate()
        managed.userDescription = value.userDescription

        switch value.item {
        case let .otpCode(code):
            let otp = ManagedOTPDetails(context: context)
            otp.digits = code.data.digits.value as NSNumber
            otp.accountName = code.data.accountName
            otp.issuer = code.data.issuer
            otp.authType = authTypeString(authType: code.type)
            otp.period = authTypePeriod(authType: code.type)
            otp.counter = authTypeCounter(authType: code.type)
            otp.algorithm = encoded(algorithm: code.data.algorithm)
            otp.secretFormat = encoded(secretFormat: code.data.secret.format)
            otp.secretData = code.data.secret.data

            managed.otpDetails = otp
        }

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
