import CryptoSwift
import Foundation

public struct AESDecryptor {
    private let key: Data
    private let iv: Data

    public init(key: Data, iv: Data) {
        self.key = key
        self.iv = iv
    }

    public func decrypt(data: Data, tag: Data) throws -> Data {
        let gcm = GCM(iv: iv.bytes, authenticationTag: tag.bytes, mode: .detached)
        let aes = try AES(key: key.bytes, blockMode: gcm, padding: .noPadding)
        if data.isEmpty { return Data() }
        let plaintextBytes = try aes.decrypt(data.bytes)
        return Data(plaintextBytes)
    }
}
