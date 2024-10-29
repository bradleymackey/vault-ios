import Foundation

public enum OTPCodeState: Equatable {
    case notReady
    case finished
    case obfuscated(ObfuscationReason)
    case visible(String)
    case locked(code: String)
    case error(PresentationError, digits: Int)
}

extension OTPCodeState {
    public enum ObfuscationReason: Equatable {
        case privacy
        case expiry
    }

    public var allowsNextCodeToBeGenerated: Bool {
        switch self {
        case .visible, .obfuscated, .locked:
            true
        case .notReady, .finished, .error:
            false
        }
    }

    public var isVisible: Bool {
        switch self {
        case .visible:
            true
        default:
            false
        }
    }
}
