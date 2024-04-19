import Foundation

/// Local settings for the codes.
public struct LocalSettingsState {
    @DefaultsStored public var pasteTimeToLive: PasteTTL

    init(defaults: Defaults) {
        _pasteTimeToLive = DefaultsStored(
            defaults: defaults,
            defaultsKey: .init("setting_paste_ttl"),
            defaultValue: .default
        )
    }
}
