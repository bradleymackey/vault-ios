import Foundation

/// An item of data that can be stored in the Vault.
public enum VaultItem: Equatable, Hashable, Sendable {
    case otpCode(OTPAuthCode)
    case secureNote(SecureNote)
}

extension VaultItem {
    public var otpCode: OTPAuthCode? {
        switch self {
        case let .otpCode(otpCode):
            otpCode
        default:
            nil
        }
    }

    public var secureNote: SecureNote? {
        switch self {
        case let .secureNote(note):
            note
        default:
            nil
        }
    }
}
