import Foundation
import SwiftData
import VaultCore

struct PersistedVaultItemEncoder {
    let context: ModelContext
    let currentDate: () -> Date

    init(context: ModelContext, currentDate: @escaping () -> Date = { Date() }) {
        self.context = context
        self.currentDate = currentDate
    }

    /// Encodes the given item, inserting it in the encoder's `context`.
    func encode(item: VaultItem.Write, existing: PersistedVaultItem? = nil) throws -> PersistedVaultItem {
        let model = if let existing {
            try encode(existingItem: existing, newData: item)
        } else {
            try encode(newData: item)
        }
        // We need to insert the model into the context at this point or the backing data
        // for the SwiftData model is not valid.
        context.insert(model)
        return model
    }
}

// MARK: - Items

extension PersistedVaultItemEncoder {
    private func fetchTagsForItem(newData: VaultItem.Write) throws -> [PersistedVaultTag] {
        let tagsForItemIds = newData.tags.map(\.id).reducedToSet()
        let itemTagsPredicate = #Predicate<PersistedVaultTag> { tagsForItemIds.contains($0.id) }
        return try context.fetch(.init(predicate: itemTagsPredicate))
    }

    private func encode(newData: VaultItem.Write) throws -> PersistedVaultItem {
        let now = currentDate()
        let noteDetails: PersistedNoteDetails? = switch newData.item {
        case let .secureNote(note): encodeSecureNoteDetails(newData: note)
        case .otpCode: nil
        }
        let otpDetails: PersistedOTPDetails? = switch newData.item {
        case let .otpCode(code): encodeOtpDetails(newData: code)
        case .secureNote: nil
        }
        return try PersistedVaultItem(
            id: UUID(),
            createdDate: now,
            updatedDate: now,
            userDescription: newData.userDescription,
            visibility: encodeVisibilityLevel(level: newData.visibility),
            searchableLevel: encodeSearchableLevel(level: newData.searchableLevel),
            searchPassphrase: newData.searchPassphase,
            lockState: encodeLockState(state: newData.lockState),
            color: newData.color.flatMap { color in
                .init(red: color.red, green: color.green, blue: color.blue)
            },
            tags: fetchTagsForItem(newData: newData),
            noteDetails: noteDetails,
            otpDetails: otpDetails
        )
    }

    private func encode(
        existingItem: PersistedVaultItem,
        newData: VaultItem.Write
    ) throws -> PersistedVaultItem {
        let now = currentDate()
        existingItem.updatedDate = now
        existingItem.userDescription = newData.userDescription
        existingItem.visibility = encodeVisibilityLevel(level: newData.visibility)
        existingItem.searchableLevel = encodeSearchableLevel(level: newData.searchableLevel)
        existingItem.searchPassphrase = newData.searchPassphase
        existingItem.tags = try fetchTagsForItem(newData: newData)
        existingItem.lockState = encodeLockState(state: newData.lockState)
        existingItem.color = newData.color.flatMap { color in
            .init(red: color.red, green: color.green, blue: color.blue)
        }
        switch newData.item {
        case let .otpCode(codeDetails):
            existingItem.otpDetails = encodeOtpDetails(newData: codeDetails)
        case let .secureNote(noteDetails):
            existingItem.noteDetails = encodeSecureNoteDetails(newData: noteDetails)
        }
        return existingItem
    }

    private func encodeSearchableLevel(level: VaultItemSearchableLevel) -> String {
        switch level {
        case .none: VaultEncodingConstants.SearchableLevel.none
        case .full: VaultEncodingConstants.SearchableLevel.full
        case .onlyTitle: VaultEncodingConstants.SearchableLevel.onlyTitle
        case .onlyPassphrase: VaultEncodingConstants.SearchableLevel.onlyPassphrase
        }
    }

    private func encodeVisibilityLevel(level: VaultItemVisibility) -> String {
        switch level {
        case .always: VaultEncodingConstants.Visibility.always
        case .onlySearch: VaultEncodingConstants.Visibility.onlySearch
        }
    }

    private func encodeLockState(state: VaultItemLockState) -> String {
        switch state {
        case .notLocked: VaultEncodingConstants.LockState.notLocked
        case .lockedWithNativeSecurity: VaultEncodingConstants.LockState.lockedWithNativeSecurity
        }
    }
}

// MARK: - OTP

extension PersistedVaultItemEncoder {
    private func encodeOtpDetails(
        newData: OTPAuthCode
    ) -> PersistedOTPDetails {
        PersistedOTPDetails(
            accountName: newData.data.accountName,
            issuer: newData.data.issuer,
            algorithm: encodedOTPAlgorithm(newData.data.algorithm),
            authType: encodedOTPAuthType(newData.type),
            counter: encodedOTPCounter(newData.type),
            digits: Int32(newData.data.digits.value),
            period: encodedOTPPeriod(newData.type),
            secretData: newData.data.secret.data,
            secretFormat: encodedOTPSecretFormat(newData.data.secret.format)
        )
    }

    private func encodedOTPAuthType(_ authType: OTPAuthType) -> String {
        switch authType {
        case .totp: VaultEncodingConstants.OTPAuthType.totp
        case .hotp: VaultEncodingConstants.OTPAuthType.hotp
        }
    }

    private func encodedOTPPeriod(_ authType: OTPAuthType) -> Int64? {
        switch authType {
        case let .totp(period): Int64(period)
        case .hotp: nil
        }
    }

    private func encodedOTPCounter(_ authType: OTPAuthType) -> Int64? {
        switch authType {
        case let .hotp(counter): Int64(counter)
        case .totp: nil
        }
    }

    private func encodedOTPAlgorithm(_ algorithm: OTPAuthAlgorithm) -> String {
        switch algorithm {
        case .sha1: VaultEncodingConstants.OTPAuthAlgorithm.sha1
        case .sha256: VaultEncodingConstants.OTPAuthAlgorithm.sha256
        case .sha512: VaultEncodingConstants.OTPAuthAlgorithm.sha512
        }
    }

    private func encodedOTPSecretFormat(_ secretFormat: OTPAuthSecret.Format) -> String {
        switch secretFormat {
        case .base32: VaultEncodingConstants.OTPAuthSecret.Format.base32
        }
    }
}

// MARK: - Note

extension PersistedVaultItemEncoder {
    private func encodeSecureNoteDetails(
        newData: SecureNote
    ) -> PersistedNoteDetails {
        PersistedNoteDetails(
            title: newData.title,
            contents: newData.contents
        )
    }
}
