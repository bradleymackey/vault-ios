import Foundation
import VaultKeygen

/// Indicates that the given item can be encrypted within a vault.
///
/// Allows encoding and decoding to a resilient format.
public protocol VaultItemEncryptable {
    associatedtype EncryptedContainer: VaultItemEncryptedContainer
    init(encryptedContainer: EncryptedContainer)
    func makeEncryptedContainer() throws -> EncryptedContainer
}

public protocol VaultItemEncryptedContainer: Codable {
    /// Identifies the type of item that this is.
    ///
    /// Definitions are in `VaultIdentifiers.Item`
    var itemIdentifier: String { get }
    /// The title that is shown externally and is not encrypted.
    var title: String { get }
}
