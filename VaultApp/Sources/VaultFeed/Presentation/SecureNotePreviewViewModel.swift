import Foundation
import VaultCore

public struct SecureNotePreviewViewModel {
    public let title: String
    public let description: String?

    public init(title: String, description: String?) {
        self.title = title
        self.description = description
    }
}
