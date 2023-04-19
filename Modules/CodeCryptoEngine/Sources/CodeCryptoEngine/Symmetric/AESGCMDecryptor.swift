import CryptoSwift
import Foundation

/// AES-GCM decryption engine.
///
/// Ciphertext and the authentication tag are used to decrypt and validate the message.
/// No padding is used for AES-GCM.
public struct AESGCMDecryptor: Decryptor {
    public typealias Message = AESGCMEncryptedMessage

    private let key: Data
    private let iv: Data

    public init(key: Data, iv: Data) {
        self.key = key
        self.iv = iv
    }

    /// - Parameter ciphertext: The encrypted message.
    /// - Parameter tag: AES-GCM authentication tag that verifies the message
    public func decrypt(message: Message) throws -> Data {
        let gcm = GCM(iv: iv.bytes, authenticationTag: message.authenticationTag.bytes, mode: .detached)
        let aes = try AES(key: key.bytes, blockMode: gcm, padding: .noPadding)
        if message.ciphertext.isEmpty { return Data() }
        let plaintextBytes = try aes.decrypt(message.ciphertext.bytes)
        return Data(plaintextBytes)
    }
}
