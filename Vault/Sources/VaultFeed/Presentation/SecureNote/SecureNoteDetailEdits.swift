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

    public var viewConfig: VaultItemViewConfiguration

    @FieldValidated(validationLogic: .stringRequiringContent)
    public var searchPassphrase: String = ""

    public var color: VaultItemColor?

    public var tags: Set<VaultItemTag.Identifier>

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
        description: String,
        contents: String,
        color: VaultItemColor?,
        viewConfig: VaultItemViewConfiguration,
        searchPassphrase: String,
        tags: Set<VaultItemTag.Identifier>,
        lockState: VaultItemLockState
    ) {
        self.description = description
        self.title = title
        self.contents = contents
        self.color = color
        self.viewConfig = viewConfig
        self.searchPassphrase = searchPassphrase
        self.tags = tags
        self.lockState = lockState
    }

    public var isValid: Bool {
        $title.isValid && $description.isValid && $contents.isValid && isPassphraseValid
    }

    private var isPassphraseValid: Bool {
        switch viewConfig {
        case .requiresSearchPassphrase: $searchPassphrase.isValid
        default: true
        }
    }
}

// MARK: - Helpers

extension SecureNoteDetailEdits {
    /// Create an `SecureNoteDetailEdits` in a blank state with initial input values, for creation.
    /// All initial values are sensible defaults.
    public static func new() -> SecureNoteDetailEdits {
        .init(
            title: "",
            description: "",
            contents: "",
            color: nil,
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            lockState: .notLocked
        )
    }
}
