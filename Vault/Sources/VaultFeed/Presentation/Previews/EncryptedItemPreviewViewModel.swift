import Foundation
import VaultCore

public struct EncryptedItemPreviewViewModel {
    /// The user-defined title of this encrypted item.
    private let title: String
    public let color: VaultItemColor

    public init(title: String, color: VaultItemColor) {
        self.title = title
        self.color = color
    }

    public var visibleTitle: String {
        if title.isBlank {
            "Untitled Item"
        } else {
            title
        }
    }
}
