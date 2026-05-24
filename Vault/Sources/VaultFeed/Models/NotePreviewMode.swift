import Foundation

/// Controls how a note appears in the at-a-glance preview tile.
public enum NotePreviewMode: String, Sendable, Codable, CaseIterable, Hashable {
    /// The note title is shown along with the first line of the body.
    case titleAndFirstLine
    /// Only the note title is shown; the body's first line is hidden.
    case titleOnly
    /// The title is replaced with "Hidden Note" and no content is shown.
    case hidden
}

extension NotePreviewMode {
    public var localizedTitle: String {
        switch self {
        case .titleAndFirstLine: localized(key: "notePreviewMode.titleAndFirstLine.localizedTitle")
        case .titleOnly: localized(key: "notePreviewMode.titleOnly.localizedTitle")
        case .hidden: localized(key: "notePreviewMode.hidden.localizedTitle")
        }
    }
}
