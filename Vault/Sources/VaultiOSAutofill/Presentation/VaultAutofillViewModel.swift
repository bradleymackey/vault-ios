import Combine
import Foundation
import VaultFeed
import VaultSettings

@MainActor
@Observable
public final class VaultAutofillViewModel {
    public enum DisplayedFeature: Equatable {
        case setupConfiguration
        case showAllCodesSelector
        case unimplemented(String)
    }

    private(set) var feature: DisplayedFeature?
    let localSettings: LocalSettings

    public init(
        localSettings: LocalSettings
    ) {
        self.localSettings = localSettings
    }

    public func show(feature: DisplayedFeature) {
        self.feature = feature
    }

    let configurationDismissSubject = PassthroughSubject<Void, Never>()

    public var configurationDismissPublisher: any Publisher<Void, Never> {
        configurationDismissSubject
    }

    public func dismissConfiguration() {
        configurationDismissSubject.send()
    }
}
