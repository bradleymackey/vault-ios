import Foundation
import VaultCore

@MainActor
@Observable
public final class VaultTagFeedViewModel<Store: VaultTagStore> {
    private let store: Store

    public init(store: Store) {
        self.store = store
    }
}

// MARK: - Strings

extension VaultTagFeedViewModel {
    public struct Strings: Sendable {
        fileprivate init() {}

        public let title = localized(key: "tagFeed.title")
    }

    public var strings: Strings {
        Strings()
    }
}
