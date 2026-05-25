import Foundation
import VaultCore

public struct VaultTextCopyAction: Equatable, Hashable, Sendable {
    public var text: String
    /// If this is `true` it indicates that the `text` should NOT be copied to the clipboard until the user has
    /// performed authentication.
    public var requiresAuthenticationToCopy: Bool
    /// Classifies the value so the pasteboard layer can apply the right sync / concealment policy.
    public var contentType: PasteboardContentType

    public init(
        text: String,
        requiresAuthenticationToCopy: Bool,
        contentType: PasteboardContentType,
    ) {
        self.text = text
        self.requiresAuthenticationToCopy = requiresAuthenticationToCopy
        self.contentType = contentType
    }
}
