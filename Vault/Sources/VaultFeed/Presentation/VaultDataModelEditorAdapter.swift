import Foundation
import FoundationExtensions
import VaultCore

@MainActor
public struct VaultDataModelEditorAdapter {
    private let dataModel: VaultDataModel

    public init(dataModel: VaultDataModel) {
        self.dataModel = dataModel
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
            searchPassphase: initialEdits.searchPassphrase,
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
                searchPassphase: edits.searchPassphrase,
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
        let newSecureNote = SecureNote(title: initialEdits.title, contents: initialEdits.contents)
        let newVaultItem = VaultItem.Write(
            relativeOrder: initialEdits.relativeOrder,
            userDescription: initialEdits.description,
            color: initialEdits.color,
            item: .secureNote(newSecureNote),
            tags: initialEdits.tags,
            visibility: initialEdits.viewConfig.visibility,
            searchableLevel: initialEdits.viewConfig.searchableLevel,
            searchPassphase: initialEdits.searchPassphrase,
            lockState: initialEdits.lockState
        )

        try await dataModel.insert(item: newVaultItem)
    }

    public func updateNote(id: Identifier<VaultItem>, item: SecureNote, edits: SecureNoteDetailEdits) async throws {
        var updatedItem = item
        updatedItem.title = edits.title
        updatedItem.contents = edits.contents
        let updatedVaultItem = VaultItem.Write(
            relativeOrder: edits.relativeOrder,
            userDescription: edits.description,
            color: edits.color,
            item: .secureNote(updatedItem),
            tags: edits.tags,
            visibility: edits.viewConfig.visibility,
            searchableLevel: edits.viewConfig.searchableLevel,
            searchPassphase: edits.searchPassphrase,
            lockState: edits.lockState
        )

        try await dataModel.update(itemID: id, data: updatedVaultItem)
    }

    public func deleteNote(id: Identifier<VaultItem>) async throws {
        try await dataModel.delete(itemID: id)
    }
}
