import Foundation
import VaultCore

public struct OTPCodeDetailFormatter {
    private let code: OTPAuthCode
    private let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        return formatter
    }()

    public init(code: OTPAuthCode) {
        self.code = code
    }

    public var algorithm: String {
        switch code.data.algorithm {
        case .sha1:
            "SHA1"
        case .sha256:
            "SHA256"
        case .sha512:
            "SHA512"
        }
    }

    public var secretType: String {
        switch code.data.secret.format {
        case .base32:
            localized(key: "codeDetail.secretType.base32")
        }
    }

    public var typeName: String {
        switch code.type {
        case .totp:
            localized(key: "codeDetail.typeName.totp")
        case .hotp:
            localized(key: "codeDetail.typeName.hotp")
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
