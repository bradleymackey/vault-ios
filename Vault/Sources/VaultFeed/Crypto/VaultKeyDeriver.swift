import CryptoEngine
import Foundation
import FoundationExtensions

/// A `KeyDeriver` that can actually be used for vault encryption.
///
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
        case testing = "vault.keygen.default.testing"
        case failing = "vault.keygen.default.testing-failing"
        case fastV1 = "vault.keygen.default.fast-v1"
        case secureV1 = "vault.keygen.default.secure-v1"

        public var id: String {
            rawValue
        }

        public var userVisibleDescription: String {
            switch self {
            case .testing: "Vault Testing"
            case .failing: "Vault Failing"
            case .fastV1: "Vault Default – FAST v1"
            case .secureV1: "Vault Default – SECURE v1"
            }
        }
    }
}

// MARK: - Derviers

extension VaultKeyDeriver {
    public static func lookup(signature: VaultKeyDeriver.Signature) -> VaultKeyDeriver {
        switch signature {
        case .testing: .testing
        case .failing: .failing
        case .fastV1: .V1.fast
        case .secureV1: .V1.secure
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

    public enum V1 {
        /// V1 fast key deriver.
        ///
        /// It's fast to run and to bruteforce (especially for a weak password), but not trivial.
        /// It still uses a combination of key derivation functions for increased security.
        ///
        /// This should be used in places where security is not required or for testing.
        public static let fast: VaultKeyDeriver = {
            var derivers = [any KeyDeriver<Bits256>]()
            derivers.append(PBKDF2_fast)
            derivers.append(HKDF_sha3_512_single)
            derivers.append(scrypt_fast)
            return VaultKeyDeriver(
                deriver: CombinationKeyDeriver(derivers: derivers),
                signature: .fastV1
            )
        }()

        /// V1 secure key deriver.
        ///
        /// This takes a significant amount of time to compute on general computing hardware, increasing
        /// the cost of a bruteforce attack significantly. It's still feasible for a user that knows a
        /// password (should take no more than a minute to compute on a standard iPhone for example).
        ///
        /// This uses a chain of different KDF algorithms to increase the cost of a bruteforce attack
        /// in the event that an offline encrypted vault is obtained by a bad actor.
        ///
        /// This is intended to be the initial production version of the KDF for the Vault app.
        public static let secure: VaultKeyDeriver = {
            var derivers = [any KeyDeriver<Bits256>]()
            // Initial PBKDF2 for strong password hashing
            derivers.append(PBKDF2_secure)
            derivers.append(HKDF_sha3_512_single)
            // Scrypt for memory-hard key derivation
            derivers.append(scrypt_secure)
            return VaultKeyDeriver(
                deriver: CombinationKeyDeriver<Bits256>(derivers: derivers),
                signature: .secureV1
            )
        }()
    }
}

// MARK: - Atoms

extension VaultKeyDeriver.V1 {
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

    /// A single round of HKDF, using SHA3's SHA512.
    private static let HKDF_sha3_512_single = HKDFKeyDeriver<Bits256>(
        parameters: .init(variant: .sha3_sha512)
    )

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
