import Foundation

public enum VaultItemDecodingError: Error, Sendable {
    case invalidOTPType
    case invalidNumberOfDigits
    case invalidAlgorithm
    case invalidSecretFormat
    case invalidSearchableLevel
    case invalidVisibility
    case invalidLockState
    case invalidTextFormat
    case missingItemDetail
    case missingPeriodForTOTP
    case missingCounterForHOTP
}
