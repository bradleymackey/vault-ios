import Foundation

public protocol VaultDetailEditor {
    func update(item: StoredVaultItem, edits: CodeDetailEdits) async throws
    func deleteCode(id: UUID) async throws
}

/// A `VaultDetailEditor` that uses a feed for updating after a given edit.
public struct VaultFeedVaultDetailEditorAdapter: VaultDetailEditor {
    private let vaultFeed: any VaultFeed
    public init(vaultFeed: any VaultFeed) {
        self.vaultFeed = vaultFeed
    }

    public func update(item: StoredVaultItem, edits: CodeDetailEdits) async throws {
        var storedItem = item
        storedItem.metadata.userDescription = edits.description

        switch item.item {
        case var .otpCode(otpCode):
            otpCode.data.accountName = edits.accountNameTitle
            otpCode.data.issuer = edits.issuerTitle
            storedItem.item = .otpCode(otpCode)
        case .secureNote:
            break
        }

        try await vaultFeed.update(id: item.id, item: storedItem.asWritable)
    }

    public func deleteCode(id: UUID) async throws {
        try await vaultFeed.delete(id: id)
    }
}
