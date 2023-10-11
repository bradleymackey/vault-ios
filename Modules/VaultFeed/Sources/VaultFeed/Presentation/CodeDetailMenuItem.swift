import Foundation

public struct CodeDetailMenuItem: Identifiable {
    public var id: String
    public var title: String
    public var systemIconName: String
    public var entries: [DetailEntry]

    public init(id: String, title: String, systemIconName: String, entries: [DetailEntry]) {
        self.id = id
        self.title = title
        self.systemIconName = systemIconName
        self.entries = entries
    }
}
