import Combine
import Foundation

@MainActor
@Observable
public final class FeedViewModel<Store: VaultStore> {
    public var codes = [StoredVaultItem]()
    public private(set) var retrievalError: PresentationError?

    private let store: Store
    private let caches: [any CodeDetailCache]

    public init(store: Store, caches: [any CodeDetailCache] = []) {
        self.store = store
        self.caches = caches
    }

    public func code(id: UUID) -> StoredVaultItem? {
        codes.first(where: { $0.id == id })
    }

    public var title: String {
        localized(key: "feedViewModel.list.title")
    }

    public var editTitle: String {
        localized(key: "feedViewModel.edit.title")
    }

    public var doneEditingTitle: String {
        localized(key: "feedViewModel.doneEditing.title")
    }
}

// MARK: - Feed

extension FeedViewModel: VaultFeed {
    public func onAppear() async {
        await reloadData()
    }

    public func reloadData() async {
        do {
            codes = try await store.retrieve()
        } catch {
            retrievalError = PresentationError(
                userTitle: localized(key: "feedRetrieval.error.title"),
                userDescription: localized(key: "feedRetrieval.error.description"),
                debugDescription: error.localizedDescription
            )
        }
    }

    public func update(id: UUID, code: StoredVaultItem.Write) async throws {
        try await store.update(id: id, item: code)
        invalidateCaches(id: id)
        await reloadData()
    }

    public func delete(id: UUID) async throws {
        try await store.delete(id: id)
        invalidateCaches(id: id)
        await reloadData()
    }

    private func invalidateCaches(id: UUID) {
        for cache in caches {
            cache.invalidateCodeDetailCache(forCodeWithID: id)
        }
    }
}
