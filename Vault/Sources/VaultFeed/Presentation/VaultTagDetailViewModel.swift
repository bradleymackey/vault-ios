import Foundation
import VaultCore

@MainActor
@Observable
public final class VaultTagDetailViewModel<Store: VaultTagStore> {
    public let strings = VaultTagDetailViewModelStrings()
    public var title = ""
    public var color: VaultItemColor = .default
    public var systemIconName = "tag.fill"
    public private(set) var saveError: PresentationError?
    public private(set) var deleteError: PresentationError?

    private let tagId: VaultItemTag.Identifier?
    private let store: Store

    public init(store: Store, existingTag: VaultItemTag.Identifier?) {
        self.store = store
        tagId = existingTag
    }

    private func makeWritableTag() -> VaultItemTag.Write {
        .init(name: title, color: color, iconName: systemIconName)
    }

    public func save() async {
        do {
            if let tagId {
                try await store.updateTag(id: tagId, item: makeWritableTag())
            } else {
                try await store.insertTag(item: makeWritableTag())
            }
        } catch {
            saveError = .init(
                userTitle: strings.saveErrorTitle,
                userDescription: strings.genericErrorDetail,
                debugDescription: error.localizedDescription
            )
        }
    }

    /// Delete the current tag, if there is a current tag.
    public func delete() async {
        do {
            guard let tagId else { return }
            try await store.deleteTag(id: tagId)
        } catch {
            deleteError = .init(
                userTitle: strings.deleteErrorTitle,
                userDescription: strings.genericErrorDetail,
                debugDescription: error.localizedDescription
            )
        }
    }

    /// Removes any error messages that are currently displaying.
    public func clearErrors() {
        saveError = nil
        deleteError = nil
    }
}

// MARK: - Strings

public struct VaultTagDetailViewModelStrings: Sendable {
    fileprivate init() {}

    public let title = localized(key: "tagDetail.title")
    public let saveErrorTitle = localized(key: "tagDetail.saveError.title")
    public let deleteErrorTitle = localized(key: "tagDetail.deleteError.title")
    public let genericErrorDetail = localized(key: "tagDetail.genericError.detail")
}
