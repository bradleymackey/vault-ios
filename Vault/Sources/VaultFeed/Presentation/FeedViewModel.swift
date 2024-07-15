import Combine
import Foundation

@MainActor
@Observable
public final class FeedViewModel<Store: VaultStore & VaultTagStoreReader> {
    public var searchQuery: String = ""
    public var codes = [VaultItem]()
    public var tags = [VaultItemTag]()
    public var errors = [VaultRetrievalResult<VaultItem>.Error]()
    public private(set) var retrievalError: PresentationError?

    private let store: Store
    private let caches: [any VaultItemCache]

    public init(store: Store, caches: [any VaultItemCache] = []) {
        self.store = store
        self.caches = caches
    }

    private var isSearching: Bool {
        sanitizedQuery != nil
    }

    public func code(id: UUID) -> VaultItem? {
        codes.first(where: { $0.id == id })
    }

    public var title: String {
        if isSearching {
            localized(key: "feedViewModel.searching.title.\(codes.count)")
        } else {
            localized(key: "feedViewModel.list.title")
        }
    }

    public var editTitle: String {
        localized(key: "feedViewModel.edit.title")
    }

    public var doneEditingTitle: String {
        localized(key: "feedViewModel.doneEditing.title")
    }

    public var searchCodesPromptTitle: String {
        localized(key: "feedViewModel.searchPrompt.title")
    }

    public var createCodeTitle: String {
        localized(key: "feedViewModel.create.code")
    }

    public var cancelEditsTitle: String {
        localized(key: "feedViewModel.cancelEdits.title")
    }

    public var createNoteTitle: String {
        localized(key: "feedViewModel.create.note")
    }

    public var inputEnterCodeManuallyTitle: String {
        localized(key: "feedViewModel.create.code.enterKeyManually.title")
    }

    public var inputSelectImageFromLibraryTitle: String {
        localized(key: "feedViewModel.create.selectImageFromLibrary.title")
    }

    public var scanCodeTitle: String {
        localized(key: "feedViewModel.create.code.scanCode.title")
    }

    public var cameraErrorTitle: String {
        localized(key: "feedViewModel.error.camera.title")
    }

    public var cameraErrorDescription: String {
        localized(key: "feedViewModel.error.camera.description")
    }
}

// MARK: - Feed

extension FeedViewModel: VaultFeed {
    public func onAppear() async {
        await reloadData()
    }

    public func reloadData() async {
        do {
            tags = try await store.retrieveTags()
            let query = VaultStoreQuery(searchText: sanitizedQuery, tags: [])
            let result = try await store.retrieve(query: query)
            codes = result.items
            errors = result.errors
        } catch {
            retrievalError = PresentationError(
                userTitle: localized(key: "feedRetrieval.error.title"),
                userDescription: localized(key: "feedRetrieval.error.description"),
                debugDescription: error.localizedDescription
            )
        }
    }

    private var sanitizedQuery: String? {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isNotEmpty else { return nil }
        return trimmed
    }

    public func create(item: VaultItem.Write) async throws {
        try await store.insert(item: item)
        await reloadData()
    }

    public func update(id: UUID, item: VaultItem.Write) async throws {
        try await store.update(id: id, item: item)
        await invalidateCaches(id: id)
        await reloadData()
    }

    public func delete(id: UUID) async throws {
        try await store.delete(id: id)
        await invalidateCaches(id: id)
        await reloadData()
    }

    private func invalidateCaches(id: UUID) async {
        for cache in caches {
            await cache.invalidateVaultItemDetailCache(forVaultItemWithID: id)
        }
    }
}
