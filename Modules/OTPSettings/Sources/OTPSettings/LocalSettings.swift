import Combine
import Foundation

@Observable
public final class LocalSettings {
    private let defaults: Defaults

    private static let localSettingsKey = Key<LocalSettingsState>("local_settings_v1")
    public var state: LocalSettingsState {
        didSet {
            try? defaults.set(state, for: Self.localSettingsKey)
        }
    }

    public init(defaults: Defaults) {
        self.defaults = defaults

        state = defaults.get(for: Self.localSettingsKey) ?? .default
    }
}
