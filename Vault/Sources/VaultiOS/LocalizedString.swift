import Foundation

/// Helper for getting a localized string from the current module.
func localized(key: String.LocalizationValue, comment: StaticString = "Localized string from VaultiOS") -> String {
    String(localized: key, table: "Feed", bundle: .module, comment: comment)
}
