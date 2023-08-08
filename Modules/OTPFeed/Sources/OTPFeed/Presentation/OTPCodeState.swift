import Foundation

public enum OTPCodeState: Equatable {
    case notReady
    case finished
    case editing
    case visible(String)
    case error(PresentationError, digits: Int)
}

public extension OTPCodeState {
    var allowsNextCodeToBeGenerated: Bool {
        isVisible
    }

    var isVisible: Bool {
        switch self {
        case .visible:
            return true
        default:
            return false
        }
    }
}
