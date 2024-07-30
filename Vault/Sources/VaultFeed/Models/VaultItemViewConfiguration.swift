import Foundation
import FoundationExtensions

public enum VaultItemViewConfiguration: Equatable, Hashable, CaseIterable, IdentifiableSelf, Sendable {
    /// The item is always visible and searchable.
    case alwaysVisible
    /// The item is only visible when searching and requires a passphrase to be entered.
    case onlyVisibleWhenSearchingRequiresPassphrase
}

extension VaultItemViewConfiguration {
    public var needsPassphrase: Bool {
        switch self {
        case .alwaysVisible: false
        case .onlyVisibleWhenSearchingRequiresPassphrase: true
        }
    }
}

// MARK: - Interop

extension VaultItemViewConfiguration {
    public init(visibility: VaultItemVisibility, searchableLevel: VaultItemSearchableLevel) {
        switch visibility {
        case .always: self = .alwaysVisible
        case .onlySearch:
            switch searchableLevel {
            case .full, .onlyTitle, .none: self = .alwaysVisible
            case .onlyPassphrase: self = .onlyVisibleWhenSearchingRequiresPassphrase
            }
        }
    }

    public var visibility: VaultItemVisibility {
        switch self {
        case .alwaysVisible: .always
        case .onlyVisibleWhenSearchingRequiresPassphrase: .onlySearch
        }
    }

    public var searchableLevel: VaultItemSearchableLevel {
        switch self {
        case .alwaysVisible: .full
        case .onlyVisibleWhenSearchingRequiresPassphrase: .onlyPassphrase
        }
    }
}

// MARK: - Localization

extension VaultItemViewConfiguration {
    public var systemIconName: String {
        switch self {
        case .alwaysVisible: "eye"
        case .onlyVisibleWhenSearchingRequiresPassphrase: "lock.fill"
        }
    }

    public var localizedTitle: String {
        switch self {
        case .alwaysVisible: localized(key: "vaultItemViewConfiguration.alwaysVisible.title")
        case .onlyVisibleWhenSearchingRequiresPassphrase: localized(
                key: "vaultItemViewConfiguration.onlyVisibleWhenSearchingRequiresPassphrase.title"
            )
        }
    }

    public var localizedSubtitle: String {
        switch self {
        case .alwaysVisible: localized(key: "vaultItemViewConfiguration.alwaysVisible.subtitle")
        case .onlyVisibleWhenSearchingRequiresPassphrase: localized(
                key: "vaultItemViewConfiguration.onlyVisibleWhenSearchingRequiresPassphrase.subtitle"
            )
        }
    }
}
