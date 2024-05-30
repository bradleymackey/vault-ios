import Foundation

public enum CustomKeyDerivers {
    public static let v1_fast = CombinationKeyDeriver(
        derivers:
        Array(repeating: HKDF_sha3_512_single, count: 50) +
            [
                PBKDF2_fast,
                scrypt_fast,
                PBKDF2_fast,
            ]
    )

    public static let v1_secure = CombinationKeyDeriver(derivers: [
        HKDF_sha3_512_single,
        HKDF_sha3_512_single,
        HKDF_sha3_512_single,
        PBKDF2_secure,
        scrypt_secure,
        PBKDF2_secure,
        scrypt_secure,
        PBKDF2_secure,
        scrypt_secure,
        PBKDF2_secure,
        HKDF_sha3_512_single,
    ])
}

// MARK: - Atoms

extension CustomKeyDerivers {
    private static let PBKDF2_fast = PBKDF2KeyDeriver(parameters: .init(
        keyLength: 32,
        iterations: 1000,
        variant: .sha384
    ))
    private static let scrypt_fast = ScryptKeyDeriver(parameters: .init(
        outputLengthBytes: 32,
        costFactor: 1 << 6,
        blockSizeFactor: 4,
        parallelizationFactor: 1
    ))
    private static let HKDF_sha3_512_single = HKDFKeyDeriver(parameters: .init(keyLength: 32, variant: .sha3_sha512))

    private static let PBKDF2_secure = PBKDF2KeyDeriver(parameters: .init(
        keyLength: 32,
        iterations: 1_234_567,
        variant: .sha384
    ))
    private static let scrypt_secure = ScryptKeyDeriver(parameters: .init(
        outputLengthBytes: 32,
        costFactor: 1 << 17,
        blockSizeFactor: 8,
        parallelizationFactor: 1
    ))
}
