import Foundation
import VaultCore

struct ManagedVaultItemDecoder {
    func decode(item: ManagedVaultItem) throws -> StoredVaultItem {
        let metadata = StoredVaultItem.Metadata(
            id: item.id,
            created: item.createdDate,
            updated: item.updatedDate,
            userDescription: item.userDescription
        )
        if let otp = item.otpDetails {
            let otpCode = try decodeOTPCode(details: otp)
            return StoredVaultItem(metadata: metadata, item: .otpCode(otpCode))
        } else if let note = item.noteDetails {
            let note = SecureNote(title: note.title, contents: note.rawContents ?? "")
            return StoredVaultItem(metadata: metadata, item: .secureNote(note))
        } else {
            // Not any kind of item that we recognise!
            throw DecodingError.missingDataInModel
        }
    }

    private func decodeOTPCode(details otp: ManagedOTPDetails) throws -> OTPAuthCode {
        try OTPAuthCode(
            type: decodeType(otp: otp),
            data: .init(
                secret: .init(data: otp.secretData, format: decodeSecretFormat(value: otp.secretFormat)),
                algorithm: decodeAlgorithm(value: otp.algorithm),
                digits: decode(digits: otp.digits),
                accountName: otp.accountName,
                issuer: otp.issuer
            )
        )
    }

    enum DecodingError: Error {
        case badDigits(NSNumber)
        case invalidType
        case missingPeriodForTOTP
        case missingCounterForHOTP
        case invalidAlgorithm
        case invalidSecretFormat
        case missingDataInModel
    }

    private func decode(digits: NSNumber) throws -> OTPAuthDigits {
        let value = digits.int32Value
        guard (Int32(UInt16.min) ... Int32(UInt16.max)).contains(value) else {
            throw DecodingError.badDigits(digits)
        }
        return OTPAuthDigits(value: UInt16(value))
    }

    private func decodeType(otp: ManagedOTPDetails) throws -> OTPAuthType {
        switch otp.authType {
        case "totp":
            guard let period = otp.period?.uint64Value else {
                throw DecodingError.missingPeriodForTOTP
            }
            return .totp(period: period)
        case "hotp":
            guard let counter = otp.counter?.uint64Value else {
                throw DecodingError.missingCounterForHOTP
            }
            return .hotp(counter: counter)
        default:
            throw DecodingError.invalidType
        }
    }

    private func decodeAlgorithm(value: String) throws -> OTPAuthAlgorithm {
        switch value {
        case "SHA1":
            return .sha1
        case "SHA256":
            return .sha256
        case "SHA512":
            return .sha512
        default:
            throw DecodingError.invalidAlgorithm
        }
    }

    private func decodeSecretFormat(value: String) throws -> OTPAuthSecret.Format {
        switch value {
        case "BASE_32":
            return .base32
        default:
            throw DecodingError.invalidSecretFormat
        }
    }
}
