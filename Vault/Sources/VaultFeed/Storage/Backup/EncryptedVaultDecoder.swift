import CryptoEngine
import Foundation
import FoundationExtensions
import VaultBackup
import VaultCore

/// @mockable
public protocol EncryptedVaultDecoder: Sendable {
    /// Decrypts and decodes an encrypted vault.
    ///
    /// - Parameter killphraseDigester: Optional. Used to rehash plaintext
    ///   killphrases found in legacy V1 backup payloads. When `nil`,
    ///   killphrases on legacy items are dropped on import rather than
    ///   persisted as plaintext.
    func decryptAndDecode(
        key: KeyData<Bits256>,
        encryptedVault: EncryptedVault,
        killphraseDigester: KillphraseDigester?,
    ) throws -> VaultApplicationPayload
    /// Throws if the given `key` cannot decrypt this vault.
    func verifyCanDecrypt(key: KeyData<Bits256>, encryptedVault: EncryptedVault) throws
}

extension EncryptedVaultDecoder {
    /// Convenience overload for callers that have no digester. Equivalent
    /// to passing `nil`.
    public func decryptAndDecode(
        key: KeyData<Bits256>,
        encryptedVault: EncryptedVault,
    ) throws -> VaultApplicationPayload {
        try decryptAndDecode(key: key, encryptedVault: encryptedVault, killphraseDigester: nil)
    }
}

/// From an encrypted vault, deconstruct to application-level items.
public final class EncryptedVaultDecoderImpl: EncryptedVaultDecoder, Sendable {
    public init() {}

    public func verifyCanDecrypt(key: KeyData<Bits256>, encryptedVault: EncryptedVault) throws {
        try rethrowing {
            try VaultBackupDecryptor(key: key).verifyCanDecrypt(encryptedVault: encryptedVault)
        }
    }

    public func decryptAndDecode(
        key: KeyData<Bits256>,
        encryptedVault: EncryptedVault,
        killphraseDigester: KillphraseDigester?,
    ) throws -> VaultApplicationPayload {
        try rethrowing {
            let backupDecoder = VaultBackupDecryptor(key: key)
            let payload = try backupDecoder.decryptBackupPayload(from: encryptedVault)
            let itemDecoder = VaultBackupItemDecoder(killphraseDigester: killphraseDigester)
            let tagDecoder = VaultBackupTagDecoder()
            return try .init(
                userDescription: payload.userDescription,
                items: payload.items.map {
                    try itemDecoder.decode(backupItem: $0)
                },
                tags: payload.tags.map {
                    try tagDecoder.decode(tag: $0)
                },
            )
        }
    }

    private func rethrowing<T>(from body: () throws -> T) throws -> T {
        do {
            return try body()
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

enum EncryptedVaultDecoderError: Equatable, Hashable, Error, LocalizedError {
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
