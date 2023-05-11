import Combine
import Foundation

@MainActor
public final class FeedViewModel<Store: OTPCodeStoreReader>: ObservableObject {
    @Published public private(set) var codes = [StoredOTPCode]()
    @Published public private(set) var codePairs = [CodePairs]()
    @Published public private(set) var retrievalError: PresentationError?

    private let store: Store

    public init(store: Store) {
        self.store = store
    }

    public struct CodePairs: Identifiable {
        public var id: String {
            codes.reduce(into: "") { $0 += $1.id.uuidString }
        }

        public var codes: [StoredOTPCode]
    }

    public func reloadData() async {
        do {
            codes = try await store.retrieve()
            let pairs = codes.chunked(into: 2)
            codePairs = pairs.map { pair in
                CodePairs(codes: pair)
            }
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
