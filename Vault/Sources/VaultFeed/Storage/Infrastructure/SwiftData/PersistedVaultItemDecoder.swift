import Foundation
import VaultCore

struct PersistedVaultItemDecoder {
    func decode(item: PersistedVaultItem) throws -> StoredVaultItem {
        let metadata = StoredVaultItem.Metadata(
            id: item.id,
            created: item.createdDate,
            updated: item.updatedDate,
            userDescription: item.userDescription,
            searchableLevel: decodeSearchableLevel(level: item.searchableLevel),
            color: decodeColor(item: item)
        )
        if let otp = item.otpDetails {
            let otpCode = try decodeOTPCode(otp: otp)
            return StoredVaultItem(metadata: metadata, item: .otpCode(otpCode))
        } else if let note = item.noteDetails {
            let note = SecureNote(
                title: note.title,
                contents: note.contents
            )
            return StoredVaultItem(metadata: metadata, item: .secureNote(note))
        } else {
            throw DecodingError.missingItemDetail
        }
    }

    enum DecodingError: Error {
        case invalidOTPType
        case invalidNumberOfDigits(Int32)
        case invalidAlgorithm
        case invalidSecretFormat
        case missingItemDetail
        case missingPeriodForTOTP
        case missingCounterForHOTP
    }
}

// MARK: - Helpers

extension PersistedVaultItemDecoder {
    private func decodeSearchableLevel(level: PersistedVaultItem.SearchableLevel) -> StoredVaultItem.Metadata
        .SearchableLevel
    {
        switch level {
        case .fullySearchable: .fullySearchable
        case .titleOnly: .titleOnly
        case .notSearchable: .notSearchable
        }
    }

    private func decodeColor(item: PersistedVaultItem) -> VaultItemColor? {
        if let color = item.color {
            VaultItemColor(red: color.red, green: color.green, blue: color.blue)
        } else {
            nil
        }
    }

    private func decodeOTPCode(otp: PersistedOTPDetails) throws -> OTPAuthCode {
        try OTPAuthCode(
            type: decodeOTPType(otp: otp),
            data: .init(
                secret: .init(data: otp.secretData, format: decodeSecretFormat(value: otp.secretFormat)),
                algorithm: decodeAlgorithm(value: otp.algorithm),
                digits: decode(digits: otp.digits),
                accountName: otp.accountName,
                issuer: otp.issuer
            )
        )
    }

    private func decodeOTPType(otp: PersistedOTPDetails) throws -> OTPAuthType {
        switch otp.authType {
        case VaultEncodingConstants.OTPAuthType.totp:
            guard let period = otp.period else {
                throw DecodingError.missingPeriodForTOTP
            }
            return .totp(period: UInt64(period))
        case VaultEncodingConstants.OTPAuthType.hotp:
            guard let counter = otp.counter else {
                throw DecodingError.missingCounterForHOTP
            }
            return .hotp(counter: UInt64(counter))
        default:
            throw DecodingError.invalidOTPType
        }
    }

    private func decode(digits: Int32) throws -> OTPAuthDigits {
        guard (Int32(UInt16.min) ... Int32(UInt16.max)).contains(digits) else {
            throw DecodingError.invalidNumberOfDigits(digits)
        }
        return OTPAuthDigits(value: UInt16(digits))
    }

    private func decodeAlgorithm(value: String) throws -> OTPAuthAlgorithm {
        switch value {
        case VaultEncodingConstants.OTPAuthAlgorithm.sha1: .sha1
        case VaultEncodingConstants.OTPAuthAlgorithm.sha256: .sha256
        case VaultEncodingConstants.OTPAuthAlgorithm.sha512: .sha512
        default: throw DecodingError.invalidAlgorithm
        }
    }

    private func decodeSecretFormat(value: String) throws -> OTPAuthSecret.Format {
        switch value {
        case VaultEncodingConstants.OTPAuthSecret.Format.base32: .base32
        default: throw DecodingError.invalidSecretFormat
        }
    }
}
