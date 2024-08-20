import CryptoEngine
import Foundation
import FoundationExtensions

public enum VaultAppKeyDerivers {
    /// A key deriver that's really fast, just for testing.
    public static let testing: ApplicationKeyDeriver = {
        let deriver = HKDFKeyDeriver<Bits256>(parameters: .init(variant: .sha3_sha512))
        return ApplicationKeyDeriver(
            deriver: deriver,
            signature: .fastV1
        )
    }()

    public enum V1 {
        /// V1 fast key deriver.
        ///
        /// It's fast to run and to bruteforce (especially for a weak password), but not trivial.
        /// It still uses a combination of key derivation functions for increased security.
        ///
        /// This should be used in places where security is not required or for testing.
        public static let fast: ApplicationKeyDeriver = {
            var derivers = [any KeyDeriver<Bits256>]()
            derivers.append(PBKDF2_fast)
            derivers.append(HKDF_sha3_512_single)
            derivers.append(scrypt_fast)
            return ApplicationKeyDeriver(
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
        public static let secure: ApplicationKeyDeriver = {
            var derivers = [any KeyDeriver<Bits256>]()
            // Initial PBKDF2 for strong password hashing
            derivers.append(PBKDF2_secure)
            derivers.append(HKDF_sha3_512_single)
            // Scrypt for memory-hard key derivation
            derivers.append(scrypt_secure)
            return ApplicationKeyDeriver(
                deriver: CombinationKeyDeriver<Bits256>(derivers: derivers),
                signature: .secureV1
            )
        }()
    }
}

// MARK: - Atoms

extension VaultAppKeyDerivers.V1 {
    private static let PBKDF2_fast = PBKDF2KeyDeriver<Bits256>(parameters: .init(
        iterations: 2000,
        variant: .sha384
    ))

    private static let scrypt_fast = ScryptKeyDeriver<Bits256>(parameters: .init(
        costFactor: 1 << 6,
        blockSizeFactor: 4,
        parallelizationFactor: 1
    ))

    /// A single round of HKDF, using SHA3's SHA512.
    private static let HKDF_sha3_512_single = HKDFKeyDeriver<Bits256>(parameters: .init(variant: .sha3_sha512))

    /// Uses a large, non-standard number of iterations with a variant that is not susceptible to
    /// length-extension attacks.
    private static let PBKDF2_secure = PBKDF2KeyDeriver<Bits256>(parameters: .init(
        iterations: 5_452_351,
        variant: .sha384
    ))

    /// Requires ~250MB of memory at peak with these current parameters.
    /// This should be fine for most iOS devices to perform locally.
    private static let scrypt_secure = ScryptKeyDeriver<Bits256>(parameters: .init(
        costFactor: 1 << 18,
        blockSizeFactor: 8,
        parallelizationFactor: 1
    ))
}
