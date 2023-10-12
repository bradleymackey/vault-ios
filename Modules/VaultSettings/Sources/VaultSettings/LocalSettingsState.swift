import Foundation

/// Local settings for the codes.
public struct LocalSettingsState {
    @DefaultsStored public var previewSize: PreviewSize
    @DefaultsStored public var pasteTimeToLive: PasteTTL

    init(defaults: Defaults) {
        _previewSize = DefaultsStored(
            defaults: defaults,
            defaultsKey: .init("setting_preview_size"),
            defaultValue: .default
        )
        _pasteTimeToLive = DefaultsStored(
            defaults: defaults,
            defaultsKey: .init("setting_paste_ttl"),
            defaultValue: .default
        )
    }
}
