import Foundation
import VaultCore

public struct SecureNotePreviewViewModel {
    /// The user-defined title of this note.
    public let title: String
    /// The user-definied description of this note.
    public let description: String?
    public let color: VaultItemColor
    public let isLocked: Bool

    public init(title: String, description: String?, color: VaultItemColor, isLocked: Bool) {
        self.title = title
        self.description = description
        self.color = color
        self.isLocked = isLocked
    }

    /// The title that is displayed in the preview.
    public var visibleTitle: String {
        if title.isEmpty {
            localized(key: "noteDetail.field.noteTitleEmpty.title")
        } else {
            title
        }
    }
}
