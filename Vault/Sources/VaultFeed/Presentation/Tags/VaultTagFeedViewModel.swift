import Foundation
import VaultCore

@MainActor
@Observable
public final class VaultTagFeedViewModel {
    public let strings = VaultTagFeedViewModelStrings()

    public init() {}
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
