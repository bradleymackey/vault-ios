import Foundation
import FoundationExtensions

/// Some data that has been encrypted with a password via keygen.
public struct SecureNoteEncrypted: Equatable, Hashable, Codable, Sendable {
    /// The version of this encryption payload.
    /// This is to allow for backwards-incompatible changes in the future.
    public var version: SemVer = "1.0.0"
    /// The encrypted payload.
    public var data: Data
    /// Additional data that represents authentication.
    /// This should be verified when decrypting, other the data might have been tampered with.
    public var authentication: Data
    /// Initialization vector used for the encryption.
    /// This is required, along with the key, to actually decrypt the `data`.
    public var encryptionIV: Data
    /// The salt that was used to generate the encryption key.
    ///
    /// This is part of the keygen process that used, alongwith the user's password, to generate the actual
    /// key that was used to encrypt this data.
    public var keygenSalt: Data
    /// The signature of the algorithm that was used to generate the encryption key.
    ///
    /// This is vault application specific, and indicates what actual algorithm was used for keygen.
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
