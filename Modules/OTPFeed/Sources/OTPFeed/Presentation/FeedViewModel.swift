import Combine
import Foundation

@MainActor
public final class FeedViewModel<Store: OTPCodeStoreReader>: ObservableObject {
    @Published public private(set) var codes = [StoredOTPCode]()
    @Published public private(set) var retrievalError: PresentationError?

    private let store: Store

    public init(store: Store) {
        self.store = store
    }

    public func reloadData() async {
        do {
            codes = try await store.retrieve()
        } catch {
            retrievalError = PresentationError(
                userTitle: localized(key: "feedRetrieval.error.title"),
                userDescription: localized(key: "feedRetrieval.error.description"),
                debugDescription: error.localizedDescription
            )
        }
    }
}
