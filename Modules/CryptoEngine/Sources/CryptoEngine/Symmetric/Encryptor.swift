import Foundation

/// A type capable of encrypting plaintext and producing an encrypted message.
public protocol Encryptor {
    associatedtype Message: EncryptedMessage
    func encrypt(plaintext: Data) throws -> Message
}
