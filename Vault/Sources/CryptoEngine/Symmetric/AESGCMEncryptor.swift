internal import CryptoSwift
import Foundation

/// AES-GCM encryption engine.
///
/// No padding will be used and the authentication tag is always seperate from the ciphertext.
public struct AESGCMEncryptor: Encryptor {
    public typealias Message = AESGCMEncryptedMessage

    private let key: Data

    public enum EncryptionError: Error {
        /// Due to an internal error, a tag was not generated.
        case noGCMTagGenerated
    }

    public init(key: Data) {
        self.key = key
    }

    /// - Parameter plaintext: the message to be encrypted with AES-GCM.
    public func encrypt(plaintext: Data, iv: Data) throws -> AESGCMEncryptedMessage {
        let gcm = GCM(iv: iv.byteArray, mode: .detached)
        let aes = try AES(key: key.byteArray, blockMode: gcm, padding: .noPadding)
        let ciphertextBytes = try aes.encrypt(plaintext.byteArray)
        guard let authenticationTag = gcm.authenticationTag else {
            throw EncryptionError.noGCMTagGenerated
        }
        return AESGCMEncryptedMessage(
            ciphertext: Data(ciphertextBytes),
            authenticationTag: Data(authenticationTag),
        )
    }
}
