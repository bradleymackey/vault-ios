import Foundation
import VaultCore

public struct EncryptedItemPreviewViewModel {
    /// The user-defined title of this encrypted item.
    private let title: String
    public let color: VaultItemColor
    public let previewMode: NotePreviewMode

    public init(title: String, color: VaultItemColor, previewMode: NotePreviewMode) {
        self.title = title
        self.color = color
        self.previewMode = previewMode
    }

    public var visibleTitle: String {
        switch previewMode {
        case .hidden:
            localized(key: "notePreviewMode.hiddenNote.title")
        case .titleAndFirstLine, .titleOnly:
            if title.isBlank {
                "Untitled Item"
            } else {
                title
            }
        }
    }
}
