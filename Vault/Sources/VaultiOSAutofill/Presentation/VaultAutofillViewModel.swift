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

    public enum RequestCancelReason: Equatable {
        case userCancelled
        case dataNotAvailable
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

    let textToInsertSubject = PassthroughSubject<String, Never>()

    public var textToInsertPublisher: any Publisher<String, Never> {
        textToInsertSubject
    }

    let cancelRequestSubject = PassthroughSubject<RequestCancelReason, Never>()

    public var cancelRequestPublisher: any Publisher<RequestCancelReason, Never> {
        cancelRequestSubject
    }

    public func dismissConfiguration() {
        configurationDismissSubject.send()
    }
}
