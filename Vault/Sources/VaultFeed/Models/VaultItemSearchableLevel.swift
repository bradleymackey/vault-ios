import Foundation
import FoundationExtensions

public enum VaultItemSearchableLevel: Equatable, Hashable, CaseIterable, IdentifiableSelf, Sendable {
    /// The item cannot be searched for.
    case none
    /// All available data in the item can be searched for.
    case full
    /// Only the title of the item can be searched for.
    case onlyTitle
    /// A secret passphrase is required to search.
    case onlyPassphrase
}

extension VaultItemSearchableLevel {
    public var systemIconName: String {
        switch self {
        case .none: "dial.low"
        case .onlyTitle: "dial.medium.fill"
        case .full: "dial.high.fill"
        case .onlyPassphrase: "lock.fill"
        }
    }

    public var localizedTitle: String {
        switch self {
        case .none: localized(key: "vaultItemSearchableLevel.none.title")
        case .full: localized(key: "vaultItemSearchableLevel.full.title")
        case .onlyTitle: localized(key: "vaultItemSearchableLevel.onlyTitle.title")
        case .onlyPassphrase: localized(key: "vaultItemSearchableLevel.onlyPassphrase.title")
        }
    }

    public var localizedSubtitle: String {
        switch self {
        case .none: localized(key: "vaultItemSearchableLevel.none.subtitle")
        case .full: localized(key: "vaultItemSearchableLevel.full.subtitle")
        case .onlyTitle: localized(key: "vaultItemSearchableLevel.onlyTitle.subtitle")
        case .onlyPassphrase: localized(key: "vaultItemSearchableLevel.onlyPassphrase.subtitle")
        }
    }
}
