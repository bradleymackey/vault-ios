import Foundation
import FoundationExtensions
import VaultCore

/// Encapsulates editing state for a given note.
///
/// This is a partial edit, which will be merged with the current model to form an update.
public struct SecureNoteDetailEdits: EditableState {
    public var relativeOrder: UInt64

    @FieldValidated(validationLogic: .alwaysValid)
    public var contents: String = ""

    public var viewConfig: VaultItemViewConfiguration

    @FieldValidated(validationLogic: .stringRequiringContent)
    public var searchPassphrase: String = ""

    public var color: VaultItemColor?

    public var tags: Set<Identifier<VaultItemTag>>

    public var textFormat: TextFormat

    public var lockState: VaultItemLockState

    public init(
        contents: String,
        textFormat: TextFormat,
        color: VaultItemColor?,
        viewConfig: VaultItemViewConfiguration,
        searchPassphrase: String,
        tags: Set<Identifier<VaultItemTag>>,
        lockState: VaultItemLockState,
        relativeOrder: UInt64
    ) {
        self.contents = contents
        self.textFormat = textFormat
        self.color = color
        self.viewConfig = viewConfig
        self.searchPassphrase = searchPassphrase
        self.tags = tags
        self.lockState = lockState
        self.relativeOrder = relativeOrder
    }

    public var isValid: Bool {
        $contents.isValid && isPassphraseValid
    }

    public var isPassphraseValid: Bool {
        switch viewConfig {
        case .requiresSearchPassphrase: $searchPassphrase.isValid
        default: true
        }
    }

    /// The description of this note, which is just the first non-empty line of content.
    public var title: String {
        let firstLine = contents
            .split(separator: "\n")
            .lazy
            .filter { !$0.isBlank }
            .first
        return String(firstLine ?? "")
    }

    /// The description of this note, which is just the second non-empty line of content.
    public var description: String {
        let secondLine = contents
            .split(separator: "\n")
            .lazy
            .filter { !$0.isBlank }
            .dropFirst()
            .first
        return String(secondLine ?? "")
    }
}

// MARK: - Helpers

extension SecureNoteDetailEdits {
    /// Create an `SecureNoteDetailEdits` in a blank state with initial input values, for creation.
    /// All initial values are sensible defaults.
    public static func new() -> SecureNoteDetailEdits {
        .init(
            contents: "",
            textFormat: .markdown,
            color: nil,
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            lockState: .notLocked,
            relativeOrder: .min
        )
    }
}
