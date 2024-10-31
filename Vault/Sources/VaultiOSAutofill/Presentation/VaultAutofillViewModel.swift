import Combine
import Foundation

@MainActor
@Observable
public final class VaultAutofillViewModel {
    public enum DisplayedFeature: Equatable {
        case setupConfiguration
        case showCodeSelector([CredentialRequest])
    }

    private(set) var feature: DisplayedFeature?

    public init() {}

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
