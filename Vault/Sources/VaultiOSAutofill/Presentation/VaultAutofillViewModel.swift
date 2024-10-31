import Combine
import Foundation
import VaultFeed
import VaultSettings

@MainActor
@Observable
final class VaultAutofillViewModel {
    enum DisplayedFeature: Equatable {
        case setupConfiguration
        case showAllCodesSelector
        case unimplemented(String)
    }

    enum RequestCancelReason: Equatable {
        case userCancelled
        case dataNotAvailable
    }

    private(set) var feature: DisplayedFeature?
    let localSettings: LocalSettings

    init(
        localSettings: LocalSettings
    ) {
        self.localSettings = localSettings
    }

    func show(feature: DisplayedFeature) {
        self.feature = feature
    }

    let configurationDismissSubject = PassthroughSubject<Void, Never>()

    var configurationDismissPublisher: any Publisher<Void, Never> {
        configurationDismissSubject
    }

    let textToInsertSubject = PassthroughSubject<String, Never>()

    var textToInsertPublisher: any Publisher<String, Never> {
        textToInsertSubject
    }

    let cancelRequestSubject = PassthroughSubject<RequestCancelReason, Never>()

    var cancelRequestPublisher: any Publisher<RequestCancelReason, Never> {
        cancelRequestSubject
    }

    func dismissConfiguration() {
        configurationDismissSubject.send()
    }
}
