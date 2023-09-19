import Foundation

/// Helper for getting a localized string from the current module.
func localized(key: String) -> String {
    NSLocalizedString(key, tableName: "Settings", bundle: .module, comment: "Localized string from settings \(key)")
}
