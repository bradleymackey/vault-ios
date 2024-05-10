import Foundation
import VaultCore

/// Encapsulates the edit state for a given code.
///
/// This is a partial edit to the code, as seen from the user's point of view.
/// Fields are separated from the raw model type to make them easier to edit in place.
/// From this model, they are merged with an existing model or written to a new model, as needed.
public struct OTPCodeDetailEdits: EditableState {
    public var codeType: OTPAuthType.Kind
    /// Only used for TOTP type codes, ignored otherwise
    public var totpPeriodLength: UInt64
    /// Only used for HOTP type codes, ignored otherwise
    public var hotpCounterValue: UInt64
    @FieldValidated(validationLogic: .otpSecretBase32)
    public var secretBase32String: String = ""
    public var algorithm: OTPAuthAlgorithm
    public var numberOfDigits: UInt16
    public var issuerTitle: String
    public var accountNameTitle: String
    public var description: String

    public init(
        codeType: OTPAuthType.Kind,
        totpPeriodLength: UInt64,
        hotpCounterValue: UInt64,
        secretBase32String: String,
        algorithm: OTPAuthAlgorithm,
        numberOfDigits: UInt16,
        issuerTitle: String,
        accountNameTitle: String,
        description: String
    ) {
        self.codeType = codeType
        self.totpPeriodLength = totpPeriodLength
        self.hotpCounterValue = hotpCounterValue
        self.secretBase32String = secretBase32String
        self.algorithm = algorithm
        self.numberOfDigits = numberOfDigits
        self.issuerTitle = issuerTitle
        self.accountNameTitle = accountNameTitle
        self.description = description
    }

    public init(hydratedFromCode code: OTPAuthCode, userDescription: String) {
        codeType = code.type.kind
        totpPeriodLength = switch code.type {
        case let .totp(period): period
        case .hotp: .max
        }
        hotpCounterValue = switch code.type {
        case .totp: .max
        case let .hotp(counter): counter
        }
        secretBase32String = code.data.secret.base32EncodedString
        algorithm = code.data.algorithm
        numberOfDigits = code.data.digits.value
        issuerTitle = code.data.issuer ?? ""
        accountNameTitle = code.data.accountName
        description = userDescription
    }

    /// Constructs an OTPAuthCode from the current state of the edits
    public func asOTPAuthCode() throws -> OTPAuthCode {
        let otpAuthType: OTPAuthType = switch codeType {
        case .totp: .totp(period: totpPeriodLength)
        case .hotp: .hotp(counter: hotpCounterValue)
        }
        let otpAuthSecret = try OTPAuthSecret.base32EncodedString(secretBase32String)
        let otpAuthCodeData = OTPAuthCodeData(
            secret: otpAuthSecret,
            algorithm: algorithm,
            digits: .init(value: numberOfDigits),
            accountName: accountNameTitle,
            issuer: issuerTitle
        )
        return OTPAuthCode(
            type: otpAuthType,
            data: otpAuthCodeData
        )
    }

    public var isValid: Bool {
        $secretBase32String.isValid
    }
}

// MARK: - Helpers

extension OTPCodeDetailEdits {
    /// Create an `OTPCodeDetailEdits` in a blank state with initial input values, for creation.
    /// All initial values are sensible defaults.
    ///
    /// Uses standards suggested by https://datatracker.ietf.org/doc/html/rfc6238
    public static func new() -> OTPCodeDetailEdits {
        .init(
            codeType: .totp,
            totpPeriodLength: 30,
            hotpCounterValue: 0,
            secretBase32String: "",
            algorithm: .sha1,
            numberOfDigits: 6,
            issuerTitle: "",
            accountNameTitle: "",
            description: ""
        )
    }
}
