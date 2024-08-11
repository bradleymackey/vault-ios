import Foundation
import VaultCore

@MainActor
@Observable
public final class VaultTagFeedViewModel {
    public private(set) var tags = [VaultItemTag]()
    public private(set) var retrievalError: PresentationError?
    public private(set) var state: State = .base

    public let store: any VaultTagStore
    public let strings = VaultTagFeedViewModelStrings()

    public enum State {
        case base, loaded
    }

    public init(store: any VaultTagStore) {
        self.store = store
    }

    public func onAppear() async {
        await reloadData()
    }

    public func reloadData() async {
        do {
            tags = try await store.retrieveTags()
            state = .loaded
        } catch {
            retrievalError = PresentationError(
                userTitle: strings.retrieveErrorTitle,
                userDescription: strings.retrieveErrorDescription,
                debugDescription: error.localizedDescription
            )
        }
    }
}

// MARK: - Strings

public struct VaultTagFeedViewModelStrings: Sendable {
    fileprivate init() {}

    public let title = localized(key: "tagFeed.title")
    public let createTagTitle = localized(key: "tagFeed.create.title")
    public let noTagsTitle = localized(key: "tagFeed.noTags.title")
    public let noTagsDescription = localized(key: "tagFeed.noTags.description")
    public let retrieveErrorTitle = localized(key: "feedRetrieval.error.title")
    public let retrieveErrorDescription = localized(key: "feedRetrieval.error.description")
}
