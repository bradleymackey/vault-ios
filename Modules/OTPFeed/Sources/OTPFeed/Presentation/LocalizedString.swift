import Foundation

/// Helper for getting a localized string from the current module.
func localized(key: String) -> String {
    NSLocalizedString(key, bundle: .module, comment: "Localized String")
}
