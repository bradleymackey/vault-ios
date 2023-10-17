import Foundation

/// An item of data that can be stored in the Vault.
public enum VaultItem: Equatable, Hashable {
    case otpCode(OTPAuthCode)
    case secureNote(SecureNote)
}

extension VaultItem {
    public var otpCode: OTPAuthCode? {
        switch self {
        case let .otpCode(otpCode):
            return otpCode
        default:
            return nil
        }
    }

    public var secureNote: SecureNote? {
        switch self {
        case let .secureNote(note):
            return note
        default:
            return nil
        }
    }
}
