import Foundation
import VaultCore

public protocol SecureNoteDetailEditor {
    func update(id: UUID, item: SecureNote, edits: SecureNoteDetailEdits) async throws
    func deleteNote(id: UUID) async throws
}

public struct VaultFeedSecureNoteDetailEditorAdapter: SecureNoteDetailEditor {
    private let vaultFeed: any VaultFeed
    public init(vaultFeed: any VaultFeed) {
        self.vaultFeed = vaultFeed
    }

    public func update(id: UUID, item: SecureNote, edits: SecureNoteDetailEdits) async throws {
        var item = item
        item.title = edits.title
        item.contents = edits.contents

        try await vaultFeed.update(id: id, item: .init(userDescription: edits.description, item: .secureNote(item)))
    }

    public func deleteNote(id: UUID) async throws {
        try await vaultFeed.delete(id: id)
    }
}
