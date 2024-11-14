import Foundation
import FoundationExtensions
import VaultCore
import VaultKeygen

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

    public var killphrase: String = ""

    /// This will only be set if the user is updating the encryption password for the item.
    ///
    /// A non-empty string implies that the encryption key should be recreated by deriving a key from this password.
    /// This will override any existing key set via `existingEncryptionKey`.
    public var newEncryptionPassword: String = ""

    /// This will only be set if the item is encrypted and already has an existing key set.
    ///
    /// If there is no password in `newEncryptionPassword`, this will be used to re-encrypt the item.
    public var existingEncryptionKey: DerivedEncryptionKey?

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
        killphrase: String,
        tags: Set<Identifier<VaultItemTag>>,
        lockState: VaultItemLockState,
        relativeOrder: UInt64,
        existingEncryptionKey: DerivedEncryptionKey?
    ) {
        self.contents = contents
        self.textFormat = textFormat
        self.color = color
        self.viewConfig = viewConfig
        self.searchPassphrase = searchPassphrase
        self.killphrase = killphrase
        self.tags = tags
        self.lockState = lockState
        self.relativeOrder = relativeOrder
        self.existingEncryptionKey = existingEncryptionKey
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

    public var isKillphraseValid: Bool {
        killphrase.isEmpty || killphrase.isNotBlank
    }

    public var killphraseIsEnabled: Bool {
        killphrase.isNotEmpty
    }

    public var killphraseEnabledText: String {
        if killphraseIsEnabled {
            "Enabled"
        } else {
            "None"
        }
    }

    private var encrypted: Bool {
        newEncryptionPassword.isNotBlank || existingEncryptionKey.isNotNil
    }

    public var encryptionEnabledText: String {
        if encrypted {
            "Enabled"
        } else {
            "None"
        }
    }

    /// The first line of the note, which is shown as the title
    public var titleLine: String {
        let firstLine = contents
            .split(separator: "\n")
            .lazy
            .filter(\.isNotBlank)
            .first
        return String(firstLine ?? "")
    }

    /// The second line of the note, used to preview the content.
    public var contentPreviewLine: String {
        guard !encrypted else { return "" }
        let secondLine = contents
            .split(separator: "\n")
            .lazy
            .filter(\.isNotBlank)
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
            killphrase: "",
            tags: [],
            lockState: .notLocked,
            relativeOrder: .min,
            existingEncryptionKey: nil
        )
    }
}
