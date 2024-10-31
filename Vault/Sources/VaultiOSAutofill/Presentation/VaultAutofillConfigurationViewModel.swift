import Combine
import Foundation

@MainActor
@Observable
final class VaultAutofillConfigurationViewModel {
    private let dismissSubject: PassthroughSubject<Void, Never>

    init(dismissSubject: PassthroughSubject<Void, Never>) {
        self.dismissSubject = dismissSubject
    }

    func dismiss() {
        dismissSubject.send()
    }
}
