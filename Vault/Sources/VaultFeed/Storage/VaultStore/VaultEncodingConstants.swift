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

    enum Visibility {
        static let always = "ALWAYS"
        static let onlySearch = "ONLY_SEARCH"
    }

    enum LockState {
        static let notLocked = "NOT_LOCKED"
        static let lockedWithNativeSecurity = "LOCKED_NATIVE"
    }

    enum SearchableLevel {
        static let none = "NONE"
        static let full = "FULL"
        static let onlyTitle = "ONLY_TITLE"
        static let onlyPassphrase = "ONLY_PASSPHRASE"
    }

    enum TextFormat {
        static let plain = "PLAIN"
        static let markdown = "MARKDOWN"
    }
}
