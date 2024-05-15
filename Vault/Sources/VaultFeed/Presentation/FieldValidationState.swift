import Foundation

public enum FieldValidationState: Equatable {
    case valid
    case invalid
    case error(message: String? = nil)
}

extension FieldValidationState {
    public var isValid: Bool {
        switch self {
        case .valid: true
        case .invalid, .error: false
        }
    }

    public var isError: Bool {
        switch self {
        case .error: true
        case .invalid, .valid: false
        }
    }

    public var message: String? {
        switch self {
        case let .error(message): message
        case .invalid, .valid: nil
        }
    }
}
