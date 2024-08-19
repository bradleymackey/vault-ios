import Foundation

/// Model type for a secure note.
public struct SecureNote: Equatable, Hashable, Sendable {
    public var title: String
    public var contents: String
    public var format: TextFormat

    public init(title: String, contents: String, format: TextFormat) {
        self.title = title
        self.contents = contents
        self.format = format
    }
}
