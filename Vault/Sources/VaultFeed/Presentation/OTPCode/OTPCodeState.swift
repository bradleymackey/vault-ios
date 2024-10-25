import Foundation

public enum OTPCodeState: Equatable {
    case notReady
    case finished
    case obfuscated(ObfuscationReason)
    case visible(String)
    case error(PresentationError, digits: Int)
}

extension OTPCodeState {
    public enum ObfuscationReason: Equatable {
        case privacy
        case expiry
        case locked(code: String)
    }

    public var allowsNextCodeToBeGenerated: Bool {
        switch self {
        case .visible, .obfuscated:
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

    /// The raw code that is able to be copied to the clipboard.
    public var copyableCode: VaultTextCopyAction? {
        switch self {
        case let .visible(code):
            VaultTextCopyAction(text: code, requiresAuthenticationToCopy: false)
        case let .obfuscated(.locked(code: code)):
            VaultTextCopyAction(text: code, requiresAuthenticationToCopy: true)
        default:
            nil
        }
    }
}
