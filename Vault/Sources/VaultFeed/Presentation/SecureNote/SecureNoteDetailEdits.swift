import Foundation

/// Encapsulates editing state for a given note.
///
/// This is a partial edit, which will be merged with the current model to form an update.
public struct SecureNoteDetailEdits: Equatable {
    public var description: String
    public var title: String
    public var contents: String

    public init(description: String, title: String, contents: String) {
        self.description = description
        self.title = title
        self.contents = contents
    }
}
