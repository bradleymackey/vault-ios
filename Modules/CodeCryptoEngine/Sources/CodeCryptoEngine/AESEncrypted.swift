import Foundation

/// Encryption result.
public struct AESEncrypted {
    public let ciphertext: Data
    public let authenticationTag: Data
}
