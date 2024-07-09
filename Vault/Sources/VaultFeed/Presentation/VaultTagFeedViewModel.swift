import Foundation
import VaultCore

@MainActor
@Observable
public final class VaultTagFeedViewModel {
    public init() {}
}

// MARK: - Strings

extension VaultTagFeedViewModel {
    public struct Strings: Sendable {
        fileprivate init() {}
        fileprivate static let shared = Strings()

        public let title = localized(key: "tagFeed.title")
    }

    public var strings: Strings {
        Strings.shared
    }
}
