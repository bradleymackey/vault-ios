import Foundation

public enum LoadingState: Equatable, Sendable {
    case loading
    case notLoading
}

extension LoadingState {
    public var isLoading: Bool {
        switch self {
        case .loading: true
        case .notLoading: false
        }
    }

    public var isNotLoading: Bool {
        !isLoading
    }
}
