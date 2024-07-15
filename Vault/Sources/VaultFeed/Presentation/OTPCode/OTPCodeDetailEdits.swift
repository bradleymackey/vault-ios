import Foundation
import VaultCore

/// Encapsulates the edit state for a given code.
///
/// This is a partial edit to the code, as seen from the user's point of view.
/// Fields are separated from the raw model type to make them easier to edit in place.
/// From this model, they are merged with an existing model or written to a new model, as needed.
public struct OTPCodeDetailEdits: EditableState, Sendable {
    public var codeType: OTPAuthType.Kind

    /// Only used for TOTP type codes, ignored otherwise
    public var totpPeriodLength: UInt64

    /// Only used for HOTP type codes, ignored otherwise
    public var hotpCounterValue: UInt64

    @FieldValidated(validationLogic: .otpSecretBase32)
    public var secretBase32String: String = ""

    public var algorithm: OTPAuthAlgorithm

    public var numberOfDigits: UInt16

    @FieldValidated(validationLogic: .stringRequiringContent)
    public var issuerTitle: String = ""

    public var accountNameTitle: String

    public var description: String

    public var viewConfig: VaultItemViewConfiguration

    @FieldValidated(validationLogic: .stringRequiringContent)
    public var searchPassphrase: String = ""

    public var color: VaultItemColor?

    public var tags: Set<VaultItemTag.Identifier>

    public init(
        codeType: OTPAuthType.Kind,
        totpPeriodLength: UInt64,
        hotpCounterValue: UInt64,
        secretBase32String: String,
        algorithm: OTPAuthAlgorithm,
        numberOfDigits: UInt16,
        issuerTitle: String,
        accountNameTitle: String,
        description: String,
        viewConfig: VaultItemViewConfiguration,
        searchPassphrase: String,
        tags: Set<VaultItemTag.Identifier>,
        color: VaultItemColor?
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
        self.viewConfig = viewConfig
        self.searchPassphrase = searchPassphrase
        self.tags = tags
        self.color = color
    }

    public init(
        hydratedFromCode code: OTPAuthCode,
        userDescription: String,
        color: VaultItemColor?,
        viewConfig: VaultItemViewConfiguration,
        searchPassphrase: String,
        tags: Set<VaultItemTag.Identifier>
    ) {
        codeType = code.type.kind
        totpPeriodLength = switch code.type {
        case let .totp(period): period
        case .hotp: OTPAuthType.TOTP.defaultPeriod
        }
        hotpCounterValue = switch code.type {
        case let .hotp(counter): counter
        case .totp: OTPAuthType.HOTP.defaultCounter
        }
        secretBase32String = code.data.secret.base32EncodedString
        algorithm = code.data.algorithm
        numberOfDigits = code.data.digits.value
        issuerTitle = code.data.issuer
        accountNameTitle = code.data.accountName
        description = userDescription
        self.tags = tags
        self.viewConfig = viewConfig
        self.searchPassphrase = searchPassphrase
        self.color = color
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
        $secretBase32String.isValid && $issuerTitle.isValid && isPassphraseValid
    }

    private var isPassphraseValid: Bool {
        switch viewConfig {
        case .onlyVisibleWhenSearchingRequiresPassphrase: $searchPassphrase.isValid
        default: true
        }
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
            totpPeriodLength: OTPAuthType.TOTP.defaultPeriod,
            hotpCounterValue: OTPAuthType.HOTP.defaultCounter,
            secretBase32String: "",
            algorithm: OTPAuthAlgorithm.default,
            numberOfDigits: OTPAuthDigits.default.value,
            issuerTitle: "",
            accountNameTitle: "",
            description: "",
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            color: nil
        )
    }
}
