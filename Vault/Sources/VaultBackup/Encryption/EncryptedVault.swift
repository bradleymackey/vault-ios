import Foundation

public struct EncryptedVault: Equatable, Codable {
    /// The encrypted payload after encryption.
    public var data: Data
    /// Additional data that represents authentication.
    public var authentication: Data

    public init(data: Data, authentication: Data) {
        self.data = data
        self.authentication = authentication
    }

    public enum CodingKeys: String, CodingKey {
        case data = "ENCRYPTED_DATA"
        case authentication = "ENCRYPTION_AUTHENTICATION"
    }
}
