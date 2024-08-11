import Foundation
import FoundationExtensions

/// Provides access to the vault data layer for the UI layer.
///
/// Uses an underlying store and provides observations to the underlying data when it changes.
/// This should be the primary way to interact with the vault data layer (and its underlying stores),
/// to ensure that we have a consistent view of the available data!
@MainActor
@Observable
public final class VaultDataModel: Sendable {
    public enum State {
        case base, loaded
    }

    // MARK: Searching Items

    public var itemsSearchQuery: String = ""
    public var itemsFilteringByTags: Set<Identifier<VaultItemTag>> = []

    private var itemsSanitizedQuery: String? {
        let trimmed = itemsSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isNotEmpty else { return nil }
        return trimmed
    }

    // MARK: Items

    public private(set) var items = [VaultItem]()
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

// MARK: Loading

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
