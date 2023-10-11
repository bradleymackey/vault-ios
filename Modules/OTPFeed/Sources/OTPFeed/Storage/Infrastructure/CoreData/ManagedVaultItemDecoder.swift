import Foundation
import OTPCore

struct ManagedVaultItemDecoder {
    func decode(code: ManagedVaultItem) throws -> GenericOTPAuthCode {
        try GenericOTPAuthCode(
            type: decodeType(code: code),
            data: .init(
                secret: .init(data: code.secretData, format: decodeSecretFormat(value: code.secretFormat)),
                algorithm: decodeAlgorithm(value: code.algorithm),
                digits: decode(digits: code.digits),
                accountName: code.accountName,
                issuer: code.issuer
            )
        )
    }

    enum DecodingError: Error {
        case badDigits(NSNumber)
        case invalidType
        case missingPeriodForTOTP
        case missingCounterForHOTP
        case invalidAlgorithm
        case invalidSecretFormat
    }

    private func decode(digits: NSNumber) throws -> OTPAuthDigits {
        let value = digits.int32Value
        guard (Int32(UInt16.min) ... Int32(UInt16.max)).contains(value) else {
            throw DecodingError.badDigits(digits)
        }
        return OTPAuthDigits(value: UInt16(value))
    }

    private func decodeType(code: ManagedVaultItem) throws -> OTPAuthType {
        switch code.authType {
        case "totp":
            guard let period = code.period?.uint64Value else {
                throw DecodingError.missingPeriodForTOTP
            }
            return .totp(period: period)
        case "hotp":
            guard let counter = code.counter?.uint64Value else {
                throw DecodingError.missingCounterForHOTP
            }
            return .hotp(counter: counter)
        default:
            throw DecodingError.invalidType
        }
    }

    private func decodeAlgorithm(value: String) throws -> OTPAuthAlgorithm {
        switch value {
        case "SHA1":
            return .sha1
        case "SHA256":
            return .sha256
        case "SHA512":
            return .sha512
        default:
            throw DecodingError.invalidAlgorithm
        }
    }

    private func decodeSecretFormat(value: String) throws -> OTPAuthSecret.Format {
        switch value {
        case "BASE_32":
            return .base32
        default:
            throw DecodingError.invalidSecretFormat
        }
    }
}
