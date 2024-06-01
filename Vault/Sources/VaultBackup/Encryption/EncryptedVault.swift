import Foundation

/// The encrypted vault that contains enough information to decrypt, given that the user only knows the key.
public struct EncryptedVault: Equatable, Codable {
    /// The version of the encrypted vault.
    private let version: Version = .v1_0_0
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
    public var keySalt: Data

    public init(data: Data, authentication: Data, encryptionIV: Data, keySalt: Data) {
        self.data = data
        self.authentication = authentication
        self.encryptionIV = encryptionIV
        self.keySalt = keySalt
    }

    public enum CodingKeys: String, CodingKey {
        case version = "ENCRYPTED_VAULT_VERSION"
        case data = "ENCRYPTED_DATA"
        case authentication = "ENCRYPTION_AUTHENTICATION"
        case encryptionIV = "ENCRYPTION_IV"
        case keySalt = "KEY_SALT"
    }
}

extension EncryptedVault {
    /// The version of the encrypted vault format (SEMVER).
    /// This is to allow for backwards-incompatible changes in the future.
    ///
    /// This is totally seperate from `VaultBackupVersion`, as the encrypted vault needs to be decoded before
    /// we can decrypt it and then read the vault contents. As such, this version number will be much more stable
    /// than `VaultBackupVersion`, as it essentially only needs to store a big block of encrypted data.
    /// Changes to the schema of the Vault, such as new vault items (or new fields on new items) do not need to change
    /// this version number.
    public enum Version: String, Codable, Equatable {
        case v1_0_0 = "1.0.0"
    }
}
