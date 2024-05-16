import Foundation
import FoundationExtensions

/// Encapsulates editing state for a given note.
///
/// This is a partial edit, which will be merged with the current model to form an update.
public struct SecureNoteDetailEdits: EditableState {
    /// The title, which validates that there is actually content in the string.
    @FieldValidated(validationLogic: .stringRequiringContent)
    public var title: String = ""

    @FieldValidated(validationLogic: .alwaysValid)
    public var description: String = ""

    @FieldValidated(validationLogic: .alwaysValid)
    public var contents: String = ""

    public var color: VaultItemColor?

    public init(title: String = "", description: String = "", contents: String = "", color: VaultItemColor? = nil) {
        self.description = description
        self.title = title
        self.contents = contents
        self.color = color
    }

    public var isValid: Bool {
        $title.isValid && $description.isValid && $contents.isValid
    }
}
