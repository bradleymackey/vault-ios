import Foundation

public struct DetailEntry: Identifiable {
    public let id: UUID = .init()
    public var title: String
    public var detail: String

    public init(title: String, detail: String) {
        self.title = title
        self.detail = detail
    }
}
