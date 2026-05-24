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
    public let previewMode: NotePreviewMode

    public init(
        title: String,
        description: String?,
        color: VaultItemColor,
        isLocked: Bool,
        textFormat: TextFormat,
        previewMode: NotePreviewMode,
    ) {
        self.title = title
        self.description = description
        self.color = color
        self.isLocked = isLocked
        self.textFormat = textFormat
        self.previewMode = previewMode
    }

    /// The title that is displayed in the preview.
    public var visibleTitle: String {
        switch previewMode {
        case .hidden:
            localized(key: "notePreviewMode.hiddenNote.title")
        case .titleAndFirstLine, .titleOnly:
            if title.isBlank {
                localized(key: "noteDetail.field.noteTitleEmpty.title")
            } else {
                title
            }
        }
    }

    /// Whether the description (first line) should be shown.
    public var showsDescription: Bool {
        previewMode == .titleAndFirstLine
    }
}
