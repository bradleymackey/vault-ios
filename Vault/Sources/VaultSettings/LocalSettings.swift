import Combine
import Foundation
import FoundationExtensions

@Observable
public final class LocalSettings {
    public var state: LocalSettingsState

    public init(defaults: Defaults) {
        state = LocalSettingsState(defaults: defaults)
    }
}
