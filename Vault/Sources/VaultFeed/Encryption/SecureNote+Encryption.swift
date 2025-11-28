import Foundation
import VaultCore

extension SecureNote: VaultItemEncryptable {
    public init(encryptedContainer: EncryptedContainer) {
        self = .init(
            title: encryptedContainer.title,
            contents: encryptedContainer.contents,
            format: encryptedContainer.format.toTextFormat(),
        )
    }

    public func makeEncryptedContainer() throws -> EncryptedContainer {
        EncryptedContainer(
            title: title,
            contents: contents,
            format: makeEncryptedContainerFormat(),
        )
    }

    private func makeEncryptedContainerFormat() -> EncryptedContainer.Format {
        switch format {
        case .plain: .plain
        case .markdown: .markdown
        }
    }

    /// Resilient format that is used during encryption/decryption.
    public struct EncryptedContainer: VaultItemEncryptedContainer {
        public var itemIdentifier: String = VaultIdentifiers.Item.secureNote
        public var title: String
        var contents: String
        var format: Format

        enum Format: String, Codable {
            case plain = "PLAIN"
            case markdown = "MARKDOWN"

            func toTextFormat() -> TextFormat {
                switch self {
                case .plain: .plain
                case .markdown: .markdown
                }
            }
        }
    }
}
