import CryptoEngine
import Foundation
import FoundationExtensions

/// The encrypted vault that contains enough information to decrypt, given that the user only knows the key.
public struct EncryptedVault: Equatable, Hashable, Codable, Sendable {
    /// The version of the encrypted vault format.
    /// This is to allow for backwards-incompatible changes in the future.
    ///
    /// This is totally seperate from the Vault's backup version, as the encrypted vault needs to be decoded before
    /// we can decrypt it and then read the vault contents. As such, this version number will be much more stable
    /// than the vault, as it essentially only needs to store a big block of encrypted data.
    /// Changes to the schema of the Vault, such as new vault items (or new fields on new items) do not need to change
    /// this version number.
    public var version: SemVer = "1.0.0"
    /// The encrypted payload after encryption.
    public var data: Data
    /// Additional data that represents authentication.
    public var authentication: Data
    /// Initialization vector used for the encryption.
    /// This is required, along with the key, to actually decrypt the `data`.
    public var encryptionIV: Data
    /// The salt that was used to generate the encryption key.
    ///
    /// This is part of the keygen process that should be used when restoring from backup.
    /// The idea is the `EncryptedVault` is imported to the device, `keySalt` is read, then `keySalt` is combined
    /// with the keygen function to generate the key needed to decrypt this `EncryptedVault` payload.
    /// If we didn't store the salt in the payload, we would be unable to derive the encryption key.
    public var keygenSalt: Data
    /// The signature of the algorithm that was used to generate the encryption key.
    public var keygenSignature: String

    public init(
        data: Data,
        authentication: Data,
        encryptionIV: Data,
        keygenSalt: Data,
        keygenSignature: String
    ) {
        self.data = data
        self.authentication = authentication
        self.encryptionIV = encryptionIV
        self.keygenSalt = keygenSalt
        self.keygenSignature = keygenSignature
    }

    public enum CodingKeys: String, CodingKey {
        case version = "ENCRYPTION_VERSION"
        case data = "ENCRYPTION_DATA"
        case authentication = "ENCRYPTION_AUTH_TAG"
        case encryptionIV = "ENCRYPTION_IV"
        case keygenSalt = "KEYGEN_SALT"
        case keygenSignature = "KEYGEN_SIGNATURE"
    }
}
