import Foundation
import VaultCore

public struct OTPCodeDetailFormatter {
    private let code: GenericOTPAuthCode
    private let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        return formatter
    }()

    public init(code: GenericOTPAuthCode) {
        self.code = code
    }

    public var algorithm: String {
        switch code.data.algorithm {
        case .sha1:
            return "SHA1"
        case .sha256:
            return "SHA256"
        case .sha512:
            return "SHA512"
        }
    }

    public var secretType: String {
        switch code.data.secret.format {
        case .base32:
            return localized(key: "codeDetail.secretType.base32")
        }
    }

    public var typeName: String {
        switch code.type {
        case .totp:
            return localized(key: "codeDetail.typeName.totp")
        case .hotp:
            return localized(key: "codeDetail.typeName.hotp")
        }
    }

    public var period: String? {
        switch code.type {
        case let .totp(period):
            let measurement: Measurement<UnitDuration> = .init(value: Double(period), unit: .seconds)
            return measurementFormatter.string(from: measurement)
        case .hotp:
            return nil
        }
    }

    public var digits: String {
        "\(code.data.digits)"
    }
}
