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

    public func code(id: UUID) -> StoredOTPCode? {
        codes.first(where: { $0.id == id })
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

    public var title: String {
        localized(key: "feedViewModel.list.title")
    }

    public var editTitle: String {
        localized(key: "feedViewModel.edit.title")
    }

    public var doneEditingTitle: String {
        localized(key: "feedViewModel.doneEditing.title")
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
