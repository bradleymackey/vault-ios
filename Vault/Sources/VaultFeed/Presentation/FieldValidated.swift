import Foundation
import FoundationExtensions
import VaultCore

/// A value that can perform validation on the value that is input with some custom logic.
@propertyWrapper
public struct FieldValidated<T> {
    public var wrappedValue: T
    private let validationLogic: FieldValidationLogic<T>

    public var projectedValue: FieldValidationState {
        validationLogic.validate(wrappedValue)
    }

    public init(wrappedValue: T, validationLogic: FieldValidationLogic<T>) {
        self.validationLogic = validationLogic
        self.wrappedValue = wrappedValue
    }
}

extension FieldValidated: Equatable where T: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

// MARK: - Validation Logic

/// Encapsulates the validator for `FieldValidated<T>`
public struct FieldValidationLogic<T: Sendable> {
    public let validate: (T) -> FieldValidationState
    public init(validate: @escaping (T) -> FieldValidationState) {
        self.validate = validate
    }
}

extension FieldValidationLogic {
    /// The validation always is valid, no matter the value.
    public static var alwaysValid: Self {
        FieldValidationLogic { _ in .valid }
    }

    /// The validation always is invalid, no matter the value.
    public static var alwaysInvalid: Self {
        FieldValidationLogic { _ in .invalid }
    }

    /// The validation always an error, no matter the value.
    public static var alwaysError: Self {
        FieldValidationLogic { _ in .error() }
    }
}

extension FieldValidationLogic where T == String {
    public static var otpSecretBase32: Self {
        FieldValidationLogic { currentValue in
            if currentValue.isEmpty { return .invalid }
            if currentValue.isBlank { return .invalid }
            do {
                _ = try OTPAuthSecret.base32EncodedString(currentValue)
                return .valid
            } catch {
                return .error(message: localized(key: "validation.rule.otpSecretBase32.invalidData"))
            }
        }
    }
}

extension FieldValidationLogic where T: StringProtocol {
    public static var stringRequiringContent: Self {
        FieldValidationLogic { currentValue in
            if currentValue.isEmpty {
                return .invalid
            }
            if currentValue.isBlank {
                return .error(message: localized(key: "validation.rule.stringRequiringContent.isBlank"))
            }
            return .valid
        }
    }
}
