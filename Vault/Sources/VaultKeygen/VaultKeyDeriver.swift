import CryptoEngine
import Foundation
import FoundationExtensions

/// A `KeyDeriver` that can actually be used in the context of the Vault app.
/// It contains a resilient `signature`, such that we can lookup the exact
/// algorithm and all parameters when we decrypt.
///
/// Things should only be made into an `VaultKeyDeriver` if they are deemed
/// to be good enough for encryption. This helps to prevent accidental errors like
/// using some random `KeyDeriver` at the application level.
public struct VaultKeyDeriver: KeyDeriver {
    /// The resilient signature that identifies this key deriver.
    ///
    /// Using the signature, this allows us to lookup the algorithm that was used
    /// during the key generation.
    public let signature: Signature

    private let deriver: any KeyDeriver<Bits256>

    public init(deriver: any KeyDeriver<Bits256>, signature: Signature) {
        self.deriver = deriver
        self.signature = signature
    }

    public func key(password: Data, salt: Data) throws -> KeyData<Bits256> {
        try deriver.key(password: password, salt: salt)
    }

    public var uniqueAlgorithmIdentifier: String {
        deriver.uniqueAlgorithmIdentifier
    }
}

extension VaultKeyDeriver: Equatable, Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.signature == rhs.signature
    }

    public func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(signature)
    }
}

extension VaultKeyDeriver {
    /// Resilient signature that is used to identify the algorithm that was used for a given keygen,
    /// so a given key can be recreated.
    public enum Signature: String, Equatable, Codable, Identifiable, CaseIterable, Sendable {
        case testing = "vault.keygen.testing"
        case failing = "vault.keygen.failing"
        case backupFastV1 = "vault.keygen.backup.fast.v1"
        case backupSecureV1 = "vault.keygen.backup.secure.v1"
        case itemFastV1 = "vault.keygen.item.fast.v1"
        case itemSecureV1 = "vault.keygen.item.secure.v1"

        public var id: String {
            rawValue
        }

        public var userVisibleDescription: String {
            switch self {
            case .testing: "Vault Testing"
            case .failing: "Vault Failing"
            case .backupFastV1: "Vault Backup (Fast, v1)"
            case .backupSecureV1: "Vault Backup (Secure, v1)"
            case .itemFastV1: "Vault Item (Fast, v1)"
            case .itemSecureV1: "Vault Item (Secure, v1)"
            }
        }

        public init(tryFromString string: String) throws {
            if let value = Self(rawValue: string) {
                self = value
            } else {
                throw MissingKeyDervierError()
            }
        }
    }
}

// MARK: - Derviers

extension VaultKeyDeriver {
    private struct MissingKeyDervierError: Error, LocalizedError {
        var errorDescription: String? { "Missing Key Deriver" }
        var failureReason: String? { "The key deriver used to generate this key is invalid" }
    }

    public static func lookup(signature: VaultKeyDeriver.Signature) -> VaultKeyDeriver {
        switch signature {
        case .testing: .testing
        case .failing: .failing
        case .backupFastV1: .Backup.Fast.v1
        case .backupSecureV1: .Backup.Secure.v1
        case .itemFastV1: .Item.Fast.v1
        case .itemSecureV1: .Item.Secure.v1
        }
    }

    /// A key deriver that's really fast, just for testing.
    public static let testing: VaultKeyDeriver = {
        let deriver = HKDFKeyDeriver<Bits256>(parameters: .init(variant: .sha3_sha512))
        return VaultKeyDeriver(
            deriver: deriver,
            signature: .testing
        )
    }()

    public static let failing: VaultKeyDeriver = .init(
        deriver: FailingKeyDeriver(), signature: .failing
    )

    /// Keyderivers that are used for backups.
    public enum Backup {
        /// Fast backup key derivers.
        public enum Fast {
            /// V1 fast key deriver for backups.
            ///
            /// It's fast to run and to bruteforce (especially for a weak password), but not trivial.
            /// It still uses a combination of key derivation functions for increased security.
            ///
            /// This should be used in places where security is not required or for testing.
            public static let v1: VaultKeyDeriver = {
                var derivers = [any KeyDeriver<Bits256>]()
                derivers.append(PBKDF2_fast)
                derivers.append(HKDF_sha3_512_single)
                derivers.append(scrypt_fast)
                return VaultKeyDeriver(
                    deriver: CombinationKeyDeriver(derivers: derivers),
                    signature: .backupFastV1
                )
            }()
        }

        public enum Secure {
            /// V1 secure key deriver for backups.
            ///
            /// This takes a significant amount of time to compute on general computing hardware, increasing
            /// the cost of a bruteforce attack significantly. It's still feasible for a user that knows a
            /// password (should take no more than a minute to compute on a standard iPhone for example).
            ///
            /// This uses a chain of different KDF algorithms to increase the cost of a bruteforce attack
            /// in the event that an offline encrypted vault is obtained by a bad actor.
            ///
            /// This is intended to be the initial production version of the KDF for the Vault app.
            public static let v1: VaultKeyDeriver = {
                var derivers = [any KeyDeriver<Bits256>]()
                // Initial PBKDF2 for strong password hashing
                derivers.append(PBKDF2_secure)
                derivers.append(HKDF_sha3_512_single)
                // Scrypt for memory-hard key derivation
                derivers.append(scrypt_secure)
                return VaultKeyDeriver(
                    deriver: CombinationKeyDeriver<Bits256>(derivers: derivers),
                    signature: .backupSecureV1
                )
            }()
        }
    }

    /// Keyderivers that are used for individual items within a vault.
    public enum Item {
        public enum Fast {
            public static let v1: VaultKeyDeriver = {
                var derivers = [any KeyDeriver<Bits256>]()
                derivers.append(scrypt_fast)
                derivers.append(PBKDF2_fast)
                return VaultKeyDeriver(
                    deriver: CombinationKeyDeriver<Bits256>(derivers: derivers),
                    signature: .itemFastV1
                )
            }()
        }

        public enum Secure {
            public static let v1: VaultKeyDeriver = {
                var derivers = [any KeyDeriver<Bits256>]()
                derivers.append(scrypt_secure)
                derivers.append(PBKDF2_secure)
                return VaultKeyDeriver(
                    deriver: CombinationKeyDeriver<Bits256>(derivers: derivers),
                    signature: .itemSecureV1
                )
            }()
        }
    }
}

// MARK: - Atoms

extension VaultKeyDeriver.Backup.Fast {
    private static let PBKDF2_fast = PBKDF2KeyDeriver<Bits256>(
        parameters: .init(
            iterations: 2000,
            variant: .sha384
        )
    )

    private static let scrypt_fast = ScryptKeyDeriver<Bits256>(
        parameters: .init(
            costFactor: 1 << 6,
            blockSizeFactor: 4,
            parallelizationFactor: 1
        )
    )
}

/// A single round of HKDF, using SHA3's SHA512.
private let HKDF_sha3_512_single = HKDFKeyDeriver<Bits256>(
    parameters: .init(variant: .sha3_sha512)
)

extension VaultKeyDeriver.Backup.Secure {
    /// Uses a large, non-standard number of iterations with a variant that is not susceptible to
    /// length-extension attacks.
    private static let PBKDF2_secure = PBKDF2KeyDeriver<Bits256>(
        parameters: .init(
            iterations: 5_452_351,
            variant: .sha384
        )
    )

    /// Requires ~250MB of memory at peak with these current parameters.
    /// This should be fine for most iOS devices to perform locally.
    private static let scrypt_secure = ScryptKeyDeriver<Bits256>(
        parameters: .init(
            costFactor: 1 << 18,
            blockSizeFactor: 8,
            parallelizationFactor: 1
        )
    )
}

extension VaultKeyDeriver.Item.Fast {
    private static let scrypt_fast = ScryptKeyDeriver<Bits256>(
        parameters: .init(
            costFactor: 1 << 6,
            blockSizeFactor: 4,
            parallelizationFactor: 1
        )
    )

    /// Uses a non-standard number of iterations with a variant that is not susceptible to
    /// length-extension attacks.
    private static let PBKDF2_fast = PBKDF2KeyDeriver<Bits256>(
        parameters: .init(
            iterations: 1001,
            variant: .sha384
        )
    )
}

extension VaultKeyDeriver.Item.Secure {
    private static let scrypt_secure = ScryptKeyDeriver<Bits256>(
        parameters: .init(
            costFactor: 1 << 8,
            blockSizeFactor: 4,
            parallelizationFactor: 1
        )
    )

    /// Uses a non-standard number of iterations with a variant that is not susceptible to
    /// length-extension attacks.
    private static let PBKDF2_secure = PBKDF2KeyDeriver<Bits256>(
        parameters: .init(
            iterations: 372_002,
            variant: .sha384
        )
    )
}
