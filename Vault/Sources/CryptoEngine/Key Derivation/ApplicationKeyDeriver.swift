import Foundation

/// A `KeyDeriver` that can actually be used for vault encryption.
///
/// It contains a resilient `signature`, such that we can lookup the exact
/// algorithm and all parameters when we decrypt.
///
/// Things should only be made into an `ApplicationKeyDeriver` if they are deemed
/// to be good enough for encryption. This helps to prevent accidental errors like
/// using some random `KeyDeriver` at the application level.
public struct ApplicationKeyDeriver: KeyDeriver {
    /// The resilient signature that identifies this key deriver.
    ///
    /// Using the signature, this allows us to lookup the algorithm that was used
    /// during the key generation.
    public let signature: Signature

    private let deriver: any KeyDeriver

    public init(deriver: any KeyDeriver, signature: Signature) {
        self.deriver = deriver
        self.signature = signature
    }

    public func key(password: Data, salt: Data) throws -> Data {
        try deriver.key(password: password, salt: salt)
    }

    public var uniqueAlgorithmIdentifier: String {
        deriver.uniqueAlgorithmIdentifier
    }

    public var userVisibleDescription: String {
        signature.userVisibleDescription
    }
}

extension ApplicationKeyDeriver {
    /// Resilient signature that is used to identify the algorithm that was used for a given keygen,
    /// so a given key can be recreated.
    public enum Signature: String, Equatable, Codable {
        case fastV1 = "vault.keygen.default.fast-v1"
        case secureV1 = "vault.keygen.default.secure-v1"

        public var userVisibleDescription: String {
            switch self {
            case .fastV1: "Vault Default – FAST v1"
            case .secureV1: "Vault Default – SECURE v1"
            }
        }
    }
}
