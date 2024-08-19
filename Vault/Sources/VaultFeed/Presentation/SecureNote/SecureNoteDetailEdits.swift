import Foundation
import FoundationExtensions
import VaultCore

/// Encapsulates editing state for a given note.
///
/// This is a partial edit, which will be merged with the current model to form an update.
public struct SecureNoteDetailEdits: EditableState {
    public var relativeOrder: UInt64

    /// The title, which validates that there is actually content in the string.
    @FieldValidated(validationLogic: .stringRequiringContent)
    public var title: String = ""

    @FieldValidated(validationLogic: .alwaysValid)
    public var contents: String = ""

    public var viewConfig: VaultItemViewConfiguration

    @FieldValidated(validationLogic: .stringRequiringContent)
    public var searchPassphrase: String = ""

    public var color: VaultItemColor?

    public var tags: Set<Identifier<VaultItemTag>>

    public var textFormat: TextFormat

    public var lockState: VaultItemLockState

    public var isLocked: Bool {
        get {
            switch lockState {
            case .notLocked: false
            case .lockedWithNativeSecurity: true
            }
        }
        set {
            lockState = newValue ? .lockedWithNativeSecurity : .notLocked
        }
    }

    public var isHiddenWithPassphrase: Bool {
        get {
            switch viewConfig {
            case .alwaysVisible: false
            case .requiresSearchPassphrase: true
            }
        }
        set {
            viewConfig = newValue ? .requiresSearchPassphrase : .alwaysVisible
        }
    }

    public init(
        title: String,
        contents: String,
        textFormat: TextFormat,
        color: VaultItemColor?,
        viewConfig: VaultItemViewConfiguration,
        searchPassphrase: String,
        tags: Set<Identifier<VaultItemTag>>,
        lockState: VaultItemLockState,
        relativeOrder: UInt64
    ) {
        self.title = title
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
        $title.isValid && $contents.isValid && isPassphraseValid
    }

    private var isPassphraseValid: Bool {
        switch viewConfig {
        case .requiresSearchPassphrase: $searchPassphrase.isValid
        default: true
        }
    }

    /// The description of this note, which is just the first line of content.
    public var description: String {
        String(contents.split(separator: "\n").first ?? "")
    }
}

// MARK: - Helpers

extension SecureNoteDetailEdits {
    /// Create an `SecureNoteDetailEdits` in a blank state with initial input values, for creation.
    /// All initial values are sensible defaults.
    public static func new() -> SecureNoteDetailEdits {
        .init(
            title: "",
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
