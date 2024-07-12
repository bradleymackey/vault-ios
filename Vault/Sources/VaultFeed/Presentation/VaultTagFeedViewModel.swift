import Foundation
import VaultCore

@MainActor
@Observable
public final class VaultTagFeedViewModel<Store: VaultTagStore> {
    public private(set) var tags = [VaultItemTag]()
    public private(set) var retrievalError: PresentationError?

    public let store: Store

    public init(store: Store) {
        self.store = store
    }

    public func onAppear() async {
        await reloadData()
    }

    public func reloadData() async {
        do {
            tags = try await store.retrieveTags()
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

extension VaultTagFeedViewModel {
    public var strings: VaultTagFeedViewModelStrings {
        VaultTagFeedViewModelStrings()
    }
}
