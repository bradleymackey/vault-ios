import Foundation
import VaultCore

/// A `OTPCodeDetailEditor` that uses a feed for updating after a given edit.
public struct VaultFeedDetailEditorAdapter {
    private let vaultFeed: any VaultFeed

    public init(vaultFeed: any VaultFeed) {
        self.vaultFeed = vaultFeed
    }
}

extension VaultFeedDetailEditorAdapter: OTPCodeDetailEditor {
    public func createCode(initialEdits: OTPCodeDetailEdits) async throws {
        let newCodeVaultItem = StoredVaultItem.Write(
            userDescription: initialEdits.description,
            item: .otpCode(initialEdits.asOTPAuthCode())
        )

        try await vaultFeed.create(item: newCodeVaultItem)
    }

    public func updateCode(id: UUID, item: OTPAuthCode, edits: OTPCodeDetailEdits) async throws {
        var item = item
        item.data.accountName = edits.accountNameTitle
        item.data.issuer = edits.issuerTitle

        try await vaultFeed.update(id: id, item: .init(userDescription: edits.description, item: .otpCode(item)))
    }

    public func deleteCode(id: UUID) async throws {
        try await vaultFeed.delete(id: id)
    }
}

extension VaultFeedDetailEditorAdapter: SecureNoteDetailEditor {
    public func createNote(initialEdits: SecureNoteDetailEdits) async throws {
        let newSecureNote = SecureNote(title: initialEdits.title, contents: initialEdits.contents)
        let newStoredVaultItem = StoredVaultItem.Write(
            userDescription: initialEdits.description,
            item: .secureNote(newSecureNote)
        )

        try await vaultFeed.create(item: newStoredVaultItem)
    }

    public func updateNote(id: UUID, item: SecureNote, edits: SecureNoteDetailEdits) async throws {
        var updatedItem = item
        updatedItem.title = edits.title
        updatedItem.contents = edits.contents
        let updatedStoredVaultItem = StoredVaultItem.Write(
            userDescription: edits.description,
            item: .secureNote(updatedItem)
        )

        try await vaultFeed.update(id: id, item: updatedStoredVaultItem)
    }

    public func deleteNote(id: UUID) async throws {
        try await vaultFeed.delete(id: id)
    }
}
