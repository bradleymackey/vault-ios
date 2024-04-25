import Foundation

/// Helper for getting a localized string from the current module.
func localized(key: String.LocalizationValue, comment: StaticString? = nil) -> String {
    String(localized: key, table: "VaultFeed", bundle: .module, comment: comment)
}
