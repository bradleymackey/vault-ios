import Foundation

public struct EncryptedVault: Equatable, Codable {
    /// The encrypted payload after encryption.
    public var data: Data
    /// Additional data that represents authentication.
    public var authentication: Data
    /// Initialization vector used for the encryption.
    /// This is required, along with the key, to actually decrypt the `data`.
    public var encryptionIV: Data

    public init(data: Data, authentication: Data, encryptionIV: Data) {
        self.data = data
        self.authentication = authentication
        self.encryptionIV = encryptionIV
    }

    public enum CodingKeys: String, CodingKey {
        case data = "ENCRYPTED_DATA"
        case authentication = "ENCRYPTION_AUTHENTICATION"
        case encryptionIV = "ENCRYPTION_IV"
    }
}
