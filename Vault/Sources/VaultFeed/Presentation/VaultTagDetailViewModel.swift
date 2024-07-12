import Foundation
import VaultCore

@MainActor
@Observable
public final class VaultTagDetailViewModel<Store: VaultTagStore> {
    private let store: Store

    public init(store: Store) {
        self.store = store
    }

    // TODO: add operations to save/edit/delete
}
