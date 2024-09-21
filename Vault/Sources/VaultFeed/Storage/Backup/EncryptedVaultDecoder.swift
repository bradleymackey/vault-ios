import CryptoEngine
import Foundation
import VaultBackup
import VaultCore

/// @mockable
public protocol EncryptedVaultDecoder {
    func decryptAndDecode(backupPassword: DerivedEncryptionKey, encryptedVault: EncryptedVault) throws
        -> VaultApplicationPayload
}

/// From an encrypted vault, deconstruct to application-level items.
public final class EncryptedVaultDecoderImpl: EncryptedVaultDecoder {
    public init() {}

    public func decryptAndDecode(
        backupPassword: DerivedEncryptionKey,
        encryptedVault: EncryptedVault
    ) throws -> VaultApplicationPayload {
        do {
            let backupDecoder = VaultBackupDecryptor(key: backupPassword.key)
            let payload = try backupDecoder.decryptBackupPayload(from: encryptedVault)
            let itemDecoder = VaultBackupItemDecoder()
            let tagDecoder = VaultBackupTagDecoder()
            return try .init(
                userDescription: payload.userDescription,
                items: payload.items.map {
                    try itemDecoder.decode(backupItem: $0)
                },
                tags: payload.tags.map {
                    try tagDecoder.decode(tag: $0)
                }
            )
        } catch let decodingError as VaultBackupDecryptor.Error {
            switch decodingError {
            case .incompatibleVersion:
                throw EncryptedVaultDecoderError.incompatibleVersion
            case .decryptionFailed:
                throw EncryptedVaultDecoderError.decryption
            case .decodingFailed:
                throw EncryptedVaultDecoderError.decoding
            }
        }
    }
}

// MARK: - Error

enum EncryptedVaultDecoderError: Error, LocalizedError {
    case incompatibleVersion
    case decryption
    case decoding

    var errorDescription: String? {
        switch self {
        case .incompatibleVersion: "Incompatible Export Version"
        case .decoding: "Decoding Failed"
        case .decryption: "Decryption Failed"
        }
    }

    var failureReason: String? {
        switch self {
        case .incompatibleVersion:
            """
            This backup was exported with a different version of the Vault app which is \
            incompatible with this version. You might need to install an older version of the app.
            """
        case .decoding:
            """
            The data within this backup was able to be decrypted, but it is malformed. \
            This might have been due to an export error or other data tampering. \
            You will need to foresically analyse the export to resolve this.
            """
        case .decryption:
            """
            Unable to decrypt this Vault. Please check that the decryption password is correct.
            """
        }
    }
}
