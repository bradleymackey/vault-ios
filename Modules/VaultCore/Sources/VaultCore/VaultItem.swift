import Foundation

/// An item of data that can be stored in the Vault.
public enum VaultItem: Equatable, Hashable {
    case otpCode(GenericOTPAuthCode)
}

public extension VaultItem {
    var otpCode: GenericOTPAuthCode? {
        switch self {
        case let .otpCode(otpCode):
            return otpCode
        }
    }
}
