import Foundation

/// An item of data that can be stored in the Vault.
public enum VaultDataItem: Equatable, Hashable {
    case otpCode(GenericOTPAuthCode)
}
