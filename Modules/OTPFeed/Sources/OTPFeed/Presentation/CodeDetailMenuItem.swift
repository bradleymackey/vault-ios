import Foundation

public struct CodeDetailMenuItem: Identifiable {
    public var id: String
    public var title: String
    public var entries: [DetailEntry]

    public init(id: String, title: String, entries: [DetailEntry]) {
        self.id = id
        self.title = title
        self.entries = entries
    }
}
