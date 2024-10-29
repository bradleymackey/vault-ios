import Foundation

public struct VaultTextCopyAction: Equatable, Hashable, Sendable {
    public var text: String
    /// If this is `true` it indicates that the `text` should NOT be copied to the clipboard until the user has
    /// performed authentication.
    public var requiresAuthenticationToCopy: Bool

    public init(text: String, requiresAuthenticationToCopy: Bool) {
        self.text = text
        self.requiresAuthenticationToCopy = requiresAuthenticationToCopy
    }
}
