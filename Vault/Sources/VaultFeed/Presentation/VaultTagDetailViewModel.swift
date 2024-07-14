import Foundation
import VaultCore

@MainActor
@Observable
public final class VaultTagDetailViewModel<Store: VaultTagStore> {
    public let strings = VaultTagDetailViewModelStrings()
    public var title: String
    public var color: VaultItemColor
    public var systemIconName: String
    public internal(set) var saveError: PresentationError?
    public internal(set) var deleteError: PresentationError?

    private let tagId: VaultItemTag.Identifier?
    private let store: Store

    public static var defaultIconOption: String {
        "tag.fill"
    }

    public static var systemIconOptions: [String] {
        [
            "tag.fill",
            "briefcase.fill",
            "tree.fill",
            "mountain.2.fill",
            "dog.fill",
            "cat.fill",
            "tortoise.fill",
            "bird.fill",
            "fish.fill",
            "carrot.fill",
            "clock.fill",
            "person.fill",
            "person.2.fill",
            "person.3.fill",
            "figure.stand",
            "figure.walk",
            "figure.mixed.cardio",
            "figure.play",
            "figure.fall",
            "figure.and.child.holdinghands",
            "figure.2.and.child.holdinghands",
            "figure.2.arms.open",
            "star.fill",
            "heart.fill",
            "flag.fill",
            "flag.2.crossed.fill",
            "figure.child.and.lock.open.fill",
            "bell.fill",
            "book.fill",
            "folder.fill",
            "paperplane.fill",
            "dumbbell.fill",
            "football.fill",
            "tennisball.fill",
            "gym.bag.fill",
            "gamecontroller.fill",
            "flag.checkered",
            "pencil",
            "scissors",
            "doc.text.fill",
            "doc.plaintext.fill",
            "doc.richtext.fill",
            "doc.on.doc.fill",
            "doc.on.clipboard.fill",
            "sun.max.fill",
            "moon.fill",
            "cloud.fill",
            "cloud.sun.fill",
            "drop.fill",
            "bolt.fill",
            "flame.fill",
        ]
    }

    public init(store: Store, existingTag: VaultItemTag?) {
        self.store = store
        if let existingTag {
            tagId = existingTag.id
            color = existingTag.color ?? .default
            title = existingTag.name
            let existingIcon = existingTag.iconName ?? Self.defaultIconOption
            let currentIcon = Self.systemIconOptions.contains(existingIcon) ? existingIcon : Self.defaultIconOption
            systemIconName = currentIcon
        } else {
            tagId = nil
            color = .default
            title = ""
            systemIconName = Self.defaultIconOption
        }
    }

    public var systemIconOptions: [String] {
        Self.systemIconOptions
    }

    private func makeWritableTag() -> VaultItemTag.Write {
        .init(name: title, color: color, iconName: systemIconName)
    }

    public var isValidToSave: Bool {
        title.isNotEmpty && !title.isBlank
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
