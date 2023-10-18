import Foundation

/// An encrypted message that can be produced by a result of encryption.
public protocol EncryptedMessage {
    var ciphertext: Data { get }
}

/// An encrypted message that includes an additional tag for authenticating the message.
public protocol AuthenticatedEncryptedMessage: EncryptedMessage {
    var authenticationTag: Data { get }
}
