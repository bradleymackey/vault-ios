import Foundation

public struct ThirdPartyLibrary: Decodable, Sendable {
    public var name: String
    public var url: URL
    public var licence: String
}

extension ThirdPartyLibrary: Identifiable {
    public var id: some Hashable {
        url
    }
}
