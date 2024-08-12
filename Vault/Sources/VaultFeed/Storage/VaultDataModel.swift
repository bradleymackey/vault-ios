import Foundation
import FoundationExtensions

/// Provides access to the vault data layer for the UI layer.
///
/// Uses an underlying store and provides observations to the underlying data when it changes.
/// This should be the primary way to interact with the vault data layer (and its underlying stores),
/// to ensure that we have a consistent view of the available data!
///
/// This is isolated to the main actor for the purposes of UI interop.
@MainActor
@Observable
public final class VaultDataModel: Sendable {
    public enum State {
        case base, loaded
    }

    // MARK: Searching Items

    public var itemsSearchQuery: String = ""
    public var itemsFilteringByTags: Set<Identifier<VaultItemTag>> = []

    public var isSearching: Bool {
        itemsSanitizedQuery != nil
    }

    private var itemsSanitizedQuery: String? {
        let trimmed = itemsSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isNotEmpty else { return nil }
        return trimmed
    }

    // MARK: Items

    public var items = [VaultItem]()
    public private(set) var itemErrors = [VaultRetrievalResult<VaultItem>.Error]()
    public private(set) var itemsState: State = .base
    public private(set) var itemsRetrievalError: PresentationError?
    private let itemCaches: [any VaultItemCache]

    // MARK: Tags

    public private(set) var allTags = [VaultItemTag]()
    public private(set) var allTagsState: State = .base
    public private(set) var allTagsRetrievalError: PresentationError?

    private let vaultStore: any VaultStore
    private let vaultTagStore: any VaultTagStore

    public init(vaultStore: any VaultStore, vaultTagStore: any VaultTagStore, itemCaches: [any VaultItemCache] = []) {
        self.vaultStore = vaultStore
        self.vaultTagStore = vaultTagStore
        self.itemCaches = itemCaches
    }
}

// MARK: - Helpers

extension VaultDataModel {
    private func invalidateCaches(itemID: Identifier<VaultItem>) async {
        for itemCache in itemCaches {
            await itemCache.invalidateVaultItemDetailCache(forVaultItemWithID: itemID)
        }
    }
}

// MARK: - Fetching

extension VaultDataModel {
    /// Reloads all data in the model.
    public func reloadData() async {
        await reloadTags()
        await reloadItems()
    }

    /// Reloads only the items of the model, based on the current query.
    public func reloadItems() async {
        do {
            let query = VaultStoreQuery(
                filterText: itemsSanitizedQuery,
                filterTags: itemsFilteringByTags
            )
            let result = try await vaultStore.retrieve(query: query)
            items = result.items
            itemErrors = result.errors
            itemsRetrievalError = nil
        } catch {
            itemsRetrievalError = PresentationError(
                userTitle: "Error Loading",
                userDescription: "Unable to load items",
                debugDescription: error.localizedDescription
            )
        }
    }

    /// Reloads only the tags of the model.
    public func reloadTags() async {
        do {
            allTags = try await vaultTagStore.retrieveTags()
            allTagsState = .loaded
        } catch {
            allTagsRetrievalError = PresentationError(
                userTitle: "Error Loading",
                userDescription: "Unable to load tags",
                debugDescription: error.localizedDescription
            )
        }
    }
}

// MARK: - Writing

extension VaultDataModel {
    public func insert(item: VaultItem.Write) async throws {
        try await vaultStore.insert(item: item)
        await reloadItems()
    }

    public func update(itemID id: Identifier<VaultItem>, data: VaultItem.Write) async throws {
        try await vaultStore.update(id: id, item: data)
        await invalidateCaches(itemID: id)
        await reloadItems()
    }

    public func delete(itemID: Identifier<VaultItem>) async throws {
        try await vaultStore.delete(id: itemID)
        await invalidateCaches(itemID: itemID)
        await reloadItems()
    }

    public func reorder(items: Set<Identifier<VaultItem>>, to position: VaultReorderingPosition) async throws {
        try await vaultStore.reorder(items: items, to: position)
        // don't reload, assume UI state has reordered items directly
    }

    public func insert(tag: VaultItemTag.Write) async throws {
        try await vaultTagStore.insertTag(item: tag)
        await reloadTags()
    }

    public func update(tagID id: Identifier<VaultItemTag>, data: VaultItemTag.Write) async throws {
        try await vaultTagStore.updateTag(id: id, item: data)
        await reloadTags()
    }

    public func delete(tagID: Identifier<VaultItemTag>) async throws {
        try await vaultTagStore.deleteTag(id: tagID)
        await reloadTags()
    }
}
