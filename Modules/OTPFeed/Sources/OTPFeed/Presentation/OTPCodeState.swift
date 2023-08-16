import Foundation

public enum OTPCodeState: Equatable {
    case notReady
    case finished
    case obfuscated
    case visible(String)
    case error(PresentationError, digits: Int)
}

public extension OTPCodeState {
    var allowsNextCodeToBeGenerated: Bool {
        switch self {
        case .visible, .obfuscated:
            return true
        case .notReady, .finished, .error:
            return false
        }
    }

    var isVisible: Bool {
        switch self {
        case .visible:
            return true
        default:
            return false
        }
    }

    var visibleCode: String? {
        switch self {
        case let .visible(code):
            return code
        default:
            return nil
        }
    }
}
