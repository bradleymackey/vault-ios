import Combine
import Foundation

@Observable
public final class LocalSettings {
    public var state: LocalSettingsState

    public init(defaults: Defaults) {
        state = LocalSettingsState(defaults: defaults)
    }
}
