import Foundation
import FoundationExtensions
import VaultCore

/// Local settings for the codes.
public struct LocalSettingsState {
    @DefaultsStored public var pasteTimeToLive: PasteTTL

    init(defaults: Defaults) {
        _pasteTimeToLive = DefaultsStored(
            defaults: defaults,
            defaultsKey: .init(VaultIdentifiers.Preferences.General.settingsPasteTTL),
            defaultValue: .default,
        )
    }
}
