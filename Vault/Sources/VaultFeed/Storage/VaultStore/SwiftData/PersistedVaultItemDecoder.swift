import Foundation
import FoundationExtensions
import VaultCore

struct PersistedVaultItemDecoder {
    func decode(item: PersistedVaultItem) throws -> VaultItem {
        let metadata = try VaultItem.Metadata(
            id: Identifier(id: item.id),
            created: item.createdDate,
            updated: item.updatedDate,
            relativeOrder: item.relativeOrder,
            userDescription: item.userDescription,
            tags: decodeTags(tags: item.tags),
            visibility: decodeVisibility(level: item.visibility),
            searchableLevel: decodeSearchableLevel(level: item.searchableLevel),
            searchPassphrase: item.searchPassphrase,
            killphrase: item.killphrase,
            lockState: decodeLockState(value: item.lockState),
            color: decodeColor(item: item)
        )
        if let otp = item.otpDetails {
            let otpCode = try decodeOTPCode(otp: otp)
            return VaultItem(metadata: metadata, item: .otpCode(otpCode))
        } else if let note = item.noteDetails {
            let note = try SecureNote(
                title: note.title,
                contents: note.contents,
                format: decodeTextFormat(value: note.format)
            )
            return VaultItem(metadata: metadata, item: .secureNote(note))
        } else {
            throw VaultItemDecodingError.missingItemDetail
        }
    }
}

// MARK: - Helpers

extension PersistedVaultItemDecoder {
    private func decodeTags(tags: [PersistedVaultTag]) -> Set<Identifier<VaultItemTag>> {
        tags.map {
            Identifier<VaultItemTag>(id: $0.id)
        }.reducedToSet()
    }

    private func decodeSearchableLevel(level: String) throws -> VaultItemSearchableLevel {
        switch level {
        case VaultEncodingConstants.SearchableLevel.full: .full
        case VaultEncodingConstants.SearchableLevel.none: .none
        case VaultEncodingConstants.SearchableLevel.onlyTitle: .onlyTitle
        case VaultEncodingConstants.SearchableLevel.onlyPassphrase: .onlyPassphrase
        default: throw VaultItemDecodingError.invalidSearchableLevel
        }
    }

    private func decodeVisibility(level: String) throws -> VaultItemVisibility {
        switch level {
        case VaultEncodingConstants.Visibility.always: .always
        case VaultEncodingConstants.Visibility.onlySearch: .onlySearch
        default: throw VaultItemDecodingError.invalidVisibility
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
                throw VaultItemDecodingError.missingPeriodForTOTP
            }
            return .totp(period: UInt64(period))
        case VaultEncodingConstants.OTPAuthType.hotp:
            guard let counter = otp.counter else {
                throw VaultItemDecodingError.missingCounterForHOTP
            }
            return .hotp(counter: UInt64(counter))
        default:
            throw VaultItemDecodingError.invalidOTPType
        }
    }

    private func decode(digits: Int32) throws -> OTPAuthDigits {
        guard (Int32(UInt16.min) ... Int32(UInt16.max)).contains(digits) else {
            throw VaultItemDecodingError.invalidNumberOfDigits
        }
        return OTPAuthDigits(value: UInt16(digits))
    }

    private func decodeAlgorithm(value: String) throws -> OTPAuthAlgorithm {
        switch value {
        case VaultEncodingConstants.OTPAuthAlgorithm.sha1: .sha1
        case VaultEncodingConstants.OTPAuthAlgorithm.sha256: .sha256
        case VaultEncodingConstants.OTPAuthAlgorithm.sha512: .sha512
        default: throw VaultItemDecodingError.invalidAlgorithm
        }
    }

    private func decodeSecretFormat(value: String) throws -> OTPAuthSecret.Format {
        switch value {
        case VaultEncodingConstants.OTPAuthSecret.Format.base32: .base32
        default: throw VaultItemDecodingError.invalidSecretFormat
        }
    }

    private func decodeLockState(value: String?) throws -> VaultItemLockState {
        switch value {
        case VaultEncodingConstants.LockState.notLocked: .notLocked
        case VaultEncodingConstants.LockState.lockedWithNativeSecurity: .lockedWithNativeSecurity
        case nil: .notLocked
        default: throw VaultItemDecodingError.invalidLockState
        }
    }

    private func decodeTextFormat(value: String) throws -> TextFormat {
        switch value {
        case VaultEncodingConstants.TextFormat.plain: .plain
        case VaultEncodingConstants.TextFormat.markdown: .markdown
        default: throw VaultItemDecodingError.invalidTextFormat
        }
    }
}
