import CryptoEngine
import Foundation

public struct BackupPassword: Equatable, Hashable {
    public var key: Data
    public var salt: Data

    public init(key: Data, salt: Data) {
        self.key = key
        self.salt = salt
    }
}

// MARK: - Keygen

extension BackupPassword {
    /// Creates an encryption key for the v1 version of an encrypted vault.
    public static func createV1EncryptionKey(
        text: String,
        salt: Data
    ) async throws -> BackupPassword {
        // FIXME: this will be way too slow to run in DEBUG, but don't want different behaviour between
        // the two builds. Need some application-layer toggle to swap these parameters out.
        // Debug can be up to 100x slower.
        //
        // Maybe have a selector so users can just pick a specific version of the key?
        // Possible options could be:
        //  - Insecure (for DEBUG)
        //  - Secure (These parameters)
        //  - Highly Secure (Even stronger, like a minute to derive the key?)

        // Derived from KeygenSpeedtest - fixed parameters for V1 of this encryption.
        let deriver = try ScryptKeyDeriver(
            password: Data(text.utf8),
            salt: salt,
            parameters: secureParametersV1
        )
        let key = try await deriver.key()
        return BackupPassword(key: key, salt: salt)
    }

    private static var secureParametersV1: ScryptKeyDeriver.Parameters {
        ScryptKeyDeriver.Parameters(
            outputLengthBytes: 32,
            costFactor: 1 << 20,
            blockSizeFactor: 16,
            parallelizationFactor: 1
        )
    }
}
