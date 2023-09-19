import Combine
import Foundation

public final class LocalSettings: ObservableObject {
    private let defaults: Defaults

    private static let localSettingsKey = Key<LocalSettingsState>("local_settings_v1")
    public var state: LocalSettingsState {
        willSet {
            objectWillChange.send()
        }
        didSet {
            try? defaults.set(state, for: Self.localSettingsKey)
        }
    }

    public init(defaults: Defaults) {
        self.defaults = defaults

        state = defaults.get(for: Self.localSettingsKey) ?? .default
    }
}
