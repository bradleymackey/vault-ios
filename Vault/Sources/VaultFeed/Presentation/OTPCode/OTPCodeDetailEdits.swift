import Foundation
import FoundationExtensions
import VaultCore

/// Encapsulates the edit state for a given code.
///
/// This is a partial edit to the code, as seen from the user's point of view.
/// Fields are separated from the raw model type to make them easier to edit in place.
/// From this model, they are merged with an existing model or written to a new model, as needed.
public struct OTPCodeDetailEdits: EditableState, Sendable {
    public var relativeOrder: UInt64?

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

    public var tags: Set<Identifier<VaultItemTag>>

    public var lockState: VaultItemLockState

    public var isLocked: Bool {
        get {
            switch lockState {
            case .notLocked: false
            case .lockedWithNativeSecurity: true
            }
        }
        set {
            lockState = newValue ? .lockedWithNativeSecurity : .notLocked
        }
    }

    public var isHiddenWithPassphrase: Bool {
        get {
            switch viewConfig {
            case .alwaysVisible: false
            case .requiresSearchPassphrase: true
            }
        }
        set {
            viewConfig = newValue ? .requiresSearchPassphrase : .alwaysVisible
        }
    }

    public init(
        codeType: OTPAuthType.Kind,
        relativeOrder: UInt64?,
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
        tags: Set<Identifier<VaultItemTag>>,
        lockState: VaultItemLockState,
        color: VaultItemColor?
    ) {
        self.codeType = codeType
        self.relativeOrder = relativeOrder
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
        self.lockState = lockState
        self.color = color
    }

    public init(
        hydratedFromCode code: OTPAuthCode,
        relativeOrder: UInt64?,
        userDescription: String,
        color: VaultItemColor?,
        viewConfig: VaultItemViewConfiguration,
        searchPassphrase: String,
        tags: Set<Identifier<VaultItemTag>>,
        lockState: VaultItemLockState
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
        self.lockState = lockState
        self.color = color
        self.relativeOrder = relativeOrder
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
        case .requiresSearchPassphrase: $searchPassphrase.isValid
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
            relativeOrder: nil,
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
            lockState: .notLocked,
            color: nil
        )
    }

    public static func new(hydratedFromCode code: OTPAuthCode) -> OTPCodeDetailEdits {
        .init(
            hydratedFromCode: code,
            relativeOrder: nil,
            userDescription: "",
            color: nil,
            viewConfig: .alwaysVisible,
            searchPassphrase: "",
            tags: [],
            lockState: .notLocked
        )
    }
}
