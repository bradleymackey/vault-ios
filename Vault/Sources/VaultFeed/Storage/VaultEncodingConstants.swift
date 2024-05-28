import Foundation

/// Hardcoded constants used to encode aspects of Vault items for storage and backup.
enum VaultEncodingConstants {
    enum OTPAuthType {
        static let totp = "totp"
        static let hotp = "hotp"
    }

    enum OTPAuthSecret {
        enum Format {
            static let base32 = "BASE_32"
        }
    }

    enum OTPAuthAlgorithm {
        static let sha1 = "SHA1"
        static let sha256 = "SHA256"
        static let sha512 = "SHA512"
    }
}
