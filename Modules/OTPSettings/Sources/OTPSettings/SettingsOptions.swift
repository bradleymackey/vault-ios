import Foundation

public final class SettingsOptions {
    private let defaults: Defaults

    public init(defaults: Defaults) {
        self.defaults = defaults
    }
}

// MARK: - PreviewSize

extension SettingsOptions: PreviewSizeSettingsProvider {
    private var previewSizeKey: Key<PreviewSize> {
        Key("preview_size_v1")
    }

    public var previewSize: PreviewSize {
        get {
            defaults.get(for: previewSizeKey) ?? .default
        }
        set {
            try? defaults.set(newValue, for: previewSizeKey)
        }
    }
}
