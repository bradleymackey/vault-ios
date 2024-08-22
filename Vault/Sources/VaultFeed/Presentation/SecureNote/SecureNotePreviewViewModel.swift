import Foundation
import VaultCore

public struct SecureNotePreviewViewModel {
    /// The user-defined title of this note.
    private let title: String
    /// The user-definied description of this note.
    public let description: String?
    public let color: VaultItemColor
    public let isLocked: Bool
    public let textFormat: TextFormat

    public init(title: String, description: String?, color: VaultItemColor, isLocked: Bool, textFormat: TextFormat) {
        self.title = title
        self.description = description
        self.color = color
        self.isLocked = isLocked
        self.textFormat = textFormat
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
