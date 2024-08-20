import Foundation
import FoundationExtensions
internal import CryptoSwift

public struct HKDFKeyDeriver<Length: KeyLength>: KeyDeriver {
    private let parameters: Parameters

    public init(parameters: Parameters) {
        self.parameters = parameters
    }

    public func key(password: Data, salt: Data) throws -> KeyData<Length> {
        let engine = try HKDF(
            password: password.bytes,
            salt: salt.bytes,
            info: nil,
            keyLength: Length.bytes,
            variant: parameters.variant.hmacVariant
        )
        let data = try Data(engine.calculate())
        return try KeyData(data: data)
    }

    public var uniqueAlgorithmIdentifier: String {
        let parameters = [
            "keyLength=\(Length.bytes)",
            "variant=\(parameters.variant)",
        ]
        let parameterDescription = parameters.joined(separator: ";")
        return "HKDF<\(parameterDescription)>"
    }
}

// MARK: - Parameters

extension HKDFKeyDeriver {
    public struct Parameters: Sendable {
        public enum Variant: Sendable {
            case sha256
            case sha3_sha512
        }

        public var variant: Variant

        public init(variant: Variant) {
            self.variant = variant
        }
    }
}

extension HKDFKeyDeriver.Parameters.Variant {
    fileprivate var hmacVariant: HMAC.Variant {
        switch self {
        case .sha256: .sha2(.sha256)
        case .sha3_sha512: .sha3(.sha512)
        }
    }
}
