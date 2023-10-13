import Foundation

public protocol VaultDetailEditor {
    func update(item: StoredVaultItem, edits: CodeDetailEdits) async throws
    func deleteCode(id: UUID) async throws
}

/// A `VaultDetailEditor` that uses a feed for updating after a given edit.
public struct VaultFeedVaultDetailEditorAdapter: VaultDetailEditor {
    private let codeFeed: any VaultFeed
    public init(codeFeed: any VaultFeed) {
        self.codeFeed = codeFeed
    }

    public func update(item: StoredVaultItem, edits: CodeDetailEdits) async throws {
        var storedCode = item
        storedCode.userDescription = edits.description

        switch item.item {
        case var .otpCode(otpCode):
            otpCode.data.accountName = edits.accountNameTitle
            otpCode.data.issuer = edits.issuerTitle
            storedCode.item = .otpCode(otpCode)
        case .secureNote:
            break
        }

        try await codeFeed.update(id: item.id, item: storedCode.asWritable)
    }

    public func deleteCode(id: UUID) async throws {
        try await codeFeed.delete(id: id)
    }
}
