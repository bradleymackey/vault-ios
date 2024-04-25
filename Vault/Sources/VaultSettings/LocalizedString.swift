import Foundation

/// Helper for getting a localized string from the current module.
func localized(key: String.LocalizationValue, comment: StaticString = "Localized string from settings") -> String {
    String(localized: key, table: "Settings", bundle: .module, comment: comment)
}
