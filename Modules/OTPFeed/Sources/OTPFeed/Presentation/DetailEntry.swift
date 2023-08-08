import Foundation

public struct DetailEntry: Identifiable {
    public let id: UUID = .init()
    public var title: String
    public var detail: String
    public var systemIconName: String

    public init(title: String, detail: String, systemIconName: String) {
        self.title = title
        self.detail = detail
        self.systemIconName = systemIconName
    }
}
