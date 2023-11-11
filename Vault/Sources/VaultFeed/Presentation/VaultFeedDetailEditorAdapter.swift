import Foundation
import VaultCore

/// A `OTPCodeDetailEditor` that uses a feed for updating after a given edit.
public struct VaultFeedDetailEditorAdapter: OTPCodeDetailEditor {
    private let vaultFeed: any VaultFeed
    public init(vaultFeed: any VaultFeed) {
        self.vaultFeed = vaultFeed
    }

    public func update(id: UUID, item: OTPAuthCode, edits: OTPCodeDetailEdits) async throws {
        var item = item
        item.data.accountName = edits.accountNameTitle
        item.data.issuer = edits.issuerTitle

        try await vaultFeed.update(id: id, item: .init(userDescription: edits.description, item: .otpCode(item)))
    }

    public func deleteCode(id: UUID) async throws {
        try await vaultFeed.delete(id: id)
    }
}
