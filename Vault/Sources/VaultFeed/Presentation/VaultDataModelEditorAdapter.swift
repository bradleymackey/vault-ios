import Foundation
import FoundationExtensions
import VaultCore
import VaultKeygen

@MainActor
public struct VaultDataModelEditorAdapter {
    private let dataModel: VaultDataModel
    private let keyDeriverFactory: any VaultKeyDeriverFactory

    public init(dataModel: VaultDataModel, keyDeriverFactory: any VaultKeyDeriverFactory) {
        self.dataModel = dataModel
        self.keyDeriverFactory = keyDeriverFactory
    }
}

extension VaultDataModelEditorAdapter: OTPCodeDetailEditor {
    public func createCode(initialEdits: OTPCodeDetailEdits) async throws {
        let newCodeVaultItem = try VaultItem.Write(
            relativeOrder: initialEdits.relativeOrder,
            userDescription: initialEdits.description,
            color: initialEdits.color,
            item: .otpCode(initialEdits.asOTPAuthCode()),
            tags: initialEdits.tags,
            visibility: initialEdits.viewConfig.visibility,
            searchableLevel: initialEdits.viewConfig.searchableLevel,
            searchPassphrase: initialEdits.searchPassphrase,
            killphrase: initialEdits.killphrase,
            lockState: initialEdits.lockState
        )

        try await dataModel.insert(item: newCodeVaultItem)
    }

    public func updateCode(id: Identifier<VaultItem>, item: OTPAuthCode, edits: OTPCodeDetailEdits) async throws {
        var item = item
        item.data.accountName = edits.accountNameTitle
        item.data.issuer = edits.issuerTitle

        try await dataModel.update(
            itemID: id,
            data: .init(
                relativeOrder: edits.relativeOrder,
                userDescription: edits.description,
                color: edits.color,
                item: .otpCode(item),
                tags: edits.tags,
                visibility: edits.viewConfig.visibility,
                searchableLevel: edits.viewConfig.searchableLevel,
                searchPassphrase: edits.searchPassphrase,
                killphrase: edits.killphrase,
                lockState: edits.lockState
            )
        )
    }

    public func deleteCode(id: Identifier<VaultItem>) async throws {
        try await dataModel.delete(itemID: id)
    }
}

extension VaultDataModelEditorAdapter: SecureNoteDetailEditor {
    public func createNote(initialEdits: SecureNoteDetailEdits) async throws {
        let newItem = try await makeNoteItem(edits: initialEdits)
        let newVaultItem = VaultItem.Write(
            relativeOrder: initialEdits.relativeOrder,
            userDescription: initialEdits.description,
            color: initialEdits.color,
            item: newItem,
            tags: initialEdits.tags,
            visibility: initialEdits.viewConfig.visibility,
            searchableLevel: initialEdits.viewConfig.searchableLevel,
            searchPassphrase: initialEdits.searchPassphrase,
            killphrase: initialEdits.killphrase,
            lockState: initialEdits.lockState
        )

        try await dataModel.insert(item: newVaultItem)
    }

    public func updateNote(id: Identifier<VaultItem>, item: SecureNote, edits: SecureNoteDetailEdits) async throws {
        let updatedItem = try await makeNoteItem(edits: edits)
        let updatedVaultItem = VaultItem.Write(
            relativeOrder: edits.relativeOrder,
            userDescription: edits.description,
            color: edits.color,
            item: updatedItem,
            tags: edits.tags,
            visibility: edits.viewConfig.visibility,
            searchableLevel: edits.viewConfig.searchableLevel,
            searchPassphrase: edits.searchPassphrase,
            killphrase: edits.killphrase,
            lockState: edits.lockState
        )

        try await dataModel.update(itemID: id, data: updatedVaultItem)
    }

    private func makeNoteItem(edits: SecureNoteDetailEdits) async throws -> VaultItem.Payload {
        let note = SecureNote(
            title: edits.title,
            contents: edits.contents,
            format: edits.textFormat
        )
        if edits.newEncryptionPassword.isNotBlank {
            // An explicit new encryption password has been specified.
            // Derive the key and encrypt the item.
            let keyDervier = keyDeriverFactory.makeVaultItemKeyDeriver()
            let encryptionKey = try await Task.continuation {
                try keyDervier.createEncryptionKey(password: edits.newEncryptionPassword)
            }
            let encryptor = VaultItemEncryptor(key: encryptionKey)
            let encryptedNote = try await Task.continuation {
                try encryptor.encrypt(item: note)
            }
            return .encryptedItem(encryptedNote)
        } else if let encryptionKey = edits.existingEncryptionKey {
            // Use the existing encryption key, as the user does not want to override the existing one.
            let encryptor = VaultItemEncryptor(key: encryptionKey)
            let encryptedNote = try await Task.continuation {
                try encryptor.encrypt(item: note)
            }
            return .encryptedItem(encryptedNote)
        } else {
            // No encryption is specified or should be used for this item.
            return .secureNote(note)
        }
    }

    public func deleteNote(id: Identifier<VaultItem>) async throws {
        try await dataModel.delete(itemID: id)
    }
}
