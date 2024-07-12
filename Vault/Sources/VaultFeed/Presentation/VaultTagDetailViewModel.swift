import Foundation
import VaultCore

@MainActor
@Observable
public final class VaultTagDetailViewModel<Store: VaultTagStore> {
    private let store: Store
    public let strings = VaultTagDetailViewModelStrings()

    public init(store: Store) {
        self.store = store
    }

    // TODO: add operations to save/edit/delete
}

// MARK: - Strings

public struct VaultTagDetailViewModelStrings: Sendable {
    fileprivate init() {}

    public let title = localized(key: "tagDetail.title")
}
