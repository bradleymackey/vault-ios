import Foundation
import FoundationExtensions

public enum VaultItemVisibility: Equatable, Hashable, CaseIterable, IdentifiableSelf, Sendable {
    /// This item is always visible in the feed and in searches.
    case always
    /// This item is only visible when searching, according to the `SearchableLevel`
    case onlySearch
}

extension VaultItemVisibility {
    public var localizedTitle: String {
        switch self {
        case .always: localized(key: "vaultItemVisibility.always.title")
        case .onlySearch: localized(key: "vaultItemVisibility.onlySearch.title")
        }
    }

    public var localizedSubtitle: String {
        switch self {
        case .always: localized(key: "vaultItemVisibility.always.subtitle")
        case .onlySearch: localized(key: "vaultItemVisibility.onlySearch.subtitle")
        }
    }
}
