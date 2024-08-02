import Foundation
import FoundationExtensions
import VaultBackup
import VaultCore

final class VaultBackupItemDecoder {
    func decode(backupItem: VaultBackupItem) throws -> VaultItem {
        try VaultItem(
            metadata: decodeMetadata(backupItem: backupItem),
            item: decodeItem(backupItem: backupItem)
        )
    }
}

// MARK: - Helpers

extension VaultBackupItemDecoder {
    private func decodeMetadata(backupItem: VaultBackupItem) -> VaultItem.Metadata {
        .init(
            id: backupItem.id,
            created: backupItem.createdDate,
            updated: backupItem.updatedDate,
            relativeOrder: backupItem.relativeOrder,
            userDescription: backupItem.userDescription,
            tags: decodeTags(ids: backupItem.tags),
            visibility: decodeVisibility(level: backupItem.visibility),
            searchableLevel: decodeSearchableLevel(level: backupItem.searchableLevel),
            searchPassphrase: backupItem.searchPassphrase,
            lockState: decodeLockState(state: backupItem.lockState),
            color: decodeColor(color: backupItem.tintColor)
        )
    }

    private func decodeTags(ids: Set<UUID>) -> Set<Identifier<VaultItemTag>> {
        ids.map {
            Identifier<VaultItemTag>(id: $0)
        }.reducedToSet()
    }

    private func decodeColor(color: VaultBackupRGBColor?) -> VaultItemColor? {
        guard let color else { return nil }
        return .init(red: color.red, green: color.green, blue: color.blue)
    }

    private func decodeItem(backupItem: VaultBackupItem) throws -> VaultItem.Payload {
        switch backupItem.item {
        case let .note(data): .secureNote(decodeSecureNote(data: data))
        case let .otp(data): try .otpCode(decodeOTPCode(data: data))
        }
    }

    private func decodeVisibility(level: VaultBackupItem.Visibility) -> VaultItemVisibility {
        switch level {
        case .always: .always
        case .onlySearch: .onlySearch
        }
    }

    private func decodeSearchableLevel(level: VaultBackupItem.SearchableLevel) -> VaultItemSearchableLevel {
        switch level {
        case .full: .full
        case .none: .none
        case .onlyTitle: .onlyTitle
        case .onlyPassphrase: .onlyPassphrase
        }
    }

    private func decodeLockState(state: VaultBackupItem.LockState) -> VaultItemLockState {
        switch state {
        case .notLocked: .notLocked
        case .lockedWithNativeSecurity: .lockedWithNativeSecurity
        }
    }
}

// MARK: - OTP Codes

extension VaultBackupItemDecoder {
    enum OTPDecodeError: Error, Equatable, Hashable {
        case invalidAuthType
        case invalidSecretFormat
        case invalidAlgorithm
    }

    enum TOTPDecodeError: Error, Equatable, Hashable {
        case missingPeriod
    }

    enum HOTPDecodeError: Error, Equatable, Hashable {
        case missingCounter
    }

    private func decodeOTPCode(data: VaultBackupItem.OTP) throws -> OTPAuthCode {
        try .init(
            type: decodeType(data: data),
            data: .init(
                secret: decodeSecret(data: data),
                algorithm: decodeAlgorithm(data: data),
                digits: OTPAuthDigits(value: data.digits),
                accountName: data.accountName,
                issuer: data.issuer
            )
        )
    }

    private func decodeType(data: VaultBackupItem.OTP) throws -> OTPAuthType {
        switch data.authType {
        case VaultEncodingConstants.OTPAuthType.totp:
            guard let period = data.period else { throw TOTPDecodeError.missingPeriod }
            return .totp(period: period)
        case VaultEncodingConstants.OTPAuthType.hotp:
            guard let counter = data.counter else { throw HOTPDecodeError.missingCounter }
            return .hotp(counter: counter)
        default:
            throw OTPDecodeError.invalidAuthType
        }
    }

    private func decodeSecret(data: VaultBackupItem.OTP) throws -> OTPAuthSecret {
        let format: OTPAuthSecret.Format = switch data.secretFormat {
        case VaultEncodingConstants.OTPAuthSecret.Format.base32: .base32
        default: throw OTPDecodeError.invalidSecretFormat
        }
        return OTPAuthSecret(
            data: data.secretData,
            format: format
        )
    }

    private func decodeAlgorithm(data: VaultBackupItem.OTP) throws -> OTPAuthAlgorithm {
        switch data.algorithm {
        case VaultEncodingConstants.OTPAuthAlgorithm.sha1: .sha1
        case VaultEncodingConstants.OTPAuthAlgorithm.sha256: .sha256
        case VaultEncodingConstants.OTPAuthAlgorithm.sha512: .sha512
        default: throw OTPDecodeError.invalidAlgorithm
        }
    }
}

// MARK: - Note

extension VaultBackupItemDecoder {
    private func decodeSecureNote(data: VaultBackupItem.Note) -> SecureNote {
        SecureNote(title: data.title, contents: data.rawContents ?? "")
    }
}
