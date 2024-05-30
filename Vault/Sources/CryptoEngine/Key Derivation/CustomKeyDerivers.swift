import Foundation

public enum CustomKeyDerivers {
    public static let v1_fast = CombinationKeyDeriver(derivers: [
        PBKDF2_fast,
        scrypt_fast,
        PBKDF2_fast,
    ])

    public static let v1_secure = CombinationKeyDeriver(derivers: [
        PBKDF2_secure,
        scrypt_secure,
        PBKDF2_secure,
        scrypt_secure,
        PBKDF2_secure,
        scrypt_secure,
        PBKDF2_secure,
    ])
}

// MARK: - Atoms

extension CustomKeyDerivers {
    private static let PBKDF2_fast = PBKDF2KeyDeriver(parameters: .init(
        keyLength: 32,
        iterations: 10000,
        variant: .sha384
    ))
    private static let PBKDF2_secure = PBKDF2KeyDeriver(parameters: .init(
        keyLength: 32,
        iterations: 1_234_567,
        variant: .sha384
    ))
    private static let scrypt_fast = ScryptKeyDeriver(parameters: .init(
        outputLengthBytes: 32,
        costFactor: 1 << 14,
        blockSizeFactor: 8,
        parallelizationFactor: 1
    ))
    private static let scrypt_secure = ScryptKeyDeriver(parameters: .init(
        outputLengthBytes: 32,
        costFactor: 1 << 17,
        blockSizeFactor: 8,
        parallelizationFactor: 1
    ))
}
