import Combine
import Foundation
import FoundationExtensions

@MainActor
@Observable
public final class FeedViewModel<Store: VaultStore & VaultTagStore> {
    public var searchQuery: String = ""
    public var filteringByTags: Set<Identifier<VaultItemTag>> = []
    public var codes = [VaultItem]()
    public var tags = [VaultItemTag]()
    public var errors = [VaultRetrievalResult<VaultItem>.Error]()
    public private(set) var retrievalError: PresentationError?
    public let store: Store

    private let caches: [any VaultItemCache]

    public init(store: Store, caches: [any VaultItemCache] = []) {
        self.store = store
        self.caches = caches
    }

    private var isSearching: Bool {
        sanitizedQuery != nil
    }

    public func code(id: Identifier<VaultItem>) -> VaultItem? {
        codes.first(where: { $0.id == id })
    }

    public func toggleFiltering(tag: Identifier<VaultItemTag>) {
        if filteringByTags.contains(tag) {
            filteringByTags.remove(tag)
        } else {
            filteringByTags.insert(tag)
        }
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
            let query = VaultStoreQuery(
                filterText: sanitizedQuery,
                filterTags: filteringByTags
            )
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

    public func update(id: Identifier<VaultItem>, item: VaultItem.Write) async throws {
        try await store.update(id: id, item: item)
        await invalidateCaches(id: id)
        await reloadData()
    }

    public func delete(id: Identifier<VaultItem>) async throws {
        try await store.delete(id: id)
        await invalidateCaches(id: id)
        await reloadData()
    }

    public func reorder(items: Set<Identifier<VaultItem>>, to position: VaultReorderingPosition) async throws {
        try await store.reorder(items: items, to: position)
    }

    private func invalidateCaches(id: Identifier<VaultItem>) async {
        for cache in caches {
            await cache.invalidateVaultItemDetailCache(forVaultItemWithID: id)
        }
    }
}
