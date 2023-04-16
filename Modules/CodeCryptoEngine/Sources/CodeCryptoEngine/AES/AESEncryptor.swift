import CryptoSwift
import Foundation

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

    public func encrypt(data: Data) throws -> AESEncrypted {
        let gcm = GCM(iv: iv.bytes, mode: .detached)
        let aes = try AES(key: key.bytes, blockMode: gcm, padding: .noPadding)
        let ciphertextBytes = try aes.encrypt(data.bytes)
        guard let authenticationTag = gcm.authenticationTag else {
            throw EncryptionError.noGCMTagGenerated
        }
        return AESEncrypted(
            ciphertext: Data(ciphertextBytes),
            authenticationTag: Data(authenticationTag)
        )
    }
}
