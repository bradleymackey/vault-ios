import Foundation
import VaultKeygen

/// Indicates that the given item can be encrypted within a vault.
///
/// Allows encoding and decoding to a resilient format.
public protocol VaultItemEncryptable {
    associatedtype EncryptedContainer: Codable
    init(encryptedContainer: EncryptedContainer)
    func makeEncryptedContainer() throws -> EncryptedContainer
}
