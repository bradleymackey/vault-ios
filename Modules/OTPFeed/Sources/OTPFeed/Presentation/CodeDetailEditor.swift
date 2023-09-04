import Foundation

/// Used by `OTPCodeDetailView` for performing actions.
public protocol CodeDetailEditor {
    func update(code: StoredOTPCode, edits: CodeDetailEdits) async throws
}

/// A `CodeDetailEditor` that uses a feed for updating after a given edit.
public struct CodeFeedCodeDetailEditorAdapter: CodeDetailEditor {
    private let codeFeed: any CodeFeed
    public init(codeFeed: any CodeFeed) {
        self.codeFeed = codeFeed
    }

    public func update(code: StoredOTPCode, edits: CodeDetailEdits) async throws {
        var storedCode = code
        storedCode.userDescription = edits.description
        storedCode.code.data.accountName = edits.accountNameTitle
        storedCode.code.data.issuer = edits.issuerTitle
        try await codeFeed.update(id: code.id, code: storedCode.asWritable)
    }
}
