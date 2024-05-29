import Foundation

/// A type capable of decrypting an encrypted message and returning plaintext.
public protocol Decryptor {
    associatedtype Message: EncryptedMessage
    func decrypt(message: Message, iv: Data) throws -> Data
}
