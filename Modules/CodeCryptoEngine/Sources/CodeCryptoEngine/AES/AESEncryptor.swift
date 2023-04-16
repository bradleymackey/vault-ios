import CryptoSwift
import Foundation

/// AES-GCM encryption engine.
///
/// No padding will be used and the authentication tag is always seperate from the ciphertext.
public struct AESEncryptor {
    private let key: Data
    private let iv: Data

    public enum EncryptionError: Error {
        case noGCMTagGenerated
    }

    public init(key: Data, iv: Data) {
        self.key = key
        self.iv = iv
    }

    /// - Parameter plaintext: the message to be encrypted with AES-GCM.
    public func encrypt(plaintext: Data) throws -> AESEncrypted {
        let gcm = GCM(iv: iv.bytes, mode: .detached)
        let aes = try AES(key: key.bytes, blockMode: gcm, padding: .noPadding)
        let ciphertextBytes = try aes.encrypt(plaintext.bytes)
        guard let authenticationTag = gcm.authenticationTag else {
            throw EncryptionError.noGCMTagGenerated
        }
        return AESEncrypted(
            ciphertext: Data(ciphertextBytes),
            authenticationTag: Data(authenticationTag)
        )
    }
}
