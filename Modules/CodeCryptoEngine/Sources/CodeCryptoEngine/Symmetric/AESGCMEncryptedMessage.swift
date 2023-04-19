import Foundation

/// An encrypted message created as a result of AES-GCM encryption.
public struct AESGCMEncryptedMessage: AuthenticatedEncryptedMessage {
    public let ciphertext: Data
    public let authenticationTag: Data

    public init(ciphertext: Data, authenticationTag: Data) {
        self.ciphertext = ciphertext
        self.authenticationTag = authenticationTag
    }
}
