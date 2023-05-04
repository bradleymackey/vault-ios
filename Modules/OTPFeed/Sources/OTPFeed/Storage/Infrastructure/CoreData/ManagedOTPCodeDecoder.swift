import Foundation
import OTPCore

struct ManagedOTPCodeDecoder {
    func decode(code: ManagedOTPCode) throws -> OTPAuthCode {
        try OTPAuthCode(
            type: decodeType(code: code),
            secret: .init(data: code.secretData, format: decodeSecretFormat(value: code.secretFormat)),
            algorithm: decodeAlgorithm(value: code.algorithm),
            digits: decode(digits: code.digits),
            accountName: code.accountName,
            issuer: code.issuer
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
        if let digits = OTPAuthDigits(rawValue: digits.intValue) {
            return digits
        } else {
            throw DecodingError.badDigits(digits)
        }
    }

    private func decodeType(code: ManagedOTPCode) throws -> OTPAuthType {
        switch code.authType {
        case "totp":
            guard let period = code.period?.uint32Value else {
                throw DecodingError.missingPeriodForTOTP
            }
            return .totp(period: period)
        case "hotp":
            guard let counter = code.counter?.uint32Value else {
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
