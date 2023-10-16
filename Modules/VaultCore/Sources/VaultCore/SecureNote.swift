import Foundation

/// Model type for a secure note.
public struct SecureNote: Equatable, Hashable {
    public var title: String
    public var contents: String

    public init(title: String, contents: String) {
        self.title = title
        self.contents = contents
    }
}
