import Foundation
internal import CryptoSwift

public struct HKDFKeyDeriver: KeyDeriver {
    private let parameters: Parameters

    public init(parameters: Parameters) {
        self.parameters = parameters
    }

    public func key(password: Data, salt: Data) throws -> Data {
        let engine = try HKDF(
            password: password.bytes,
            salt: salt.bytes,
            info: nil,
            keyLength: parameters.keyLength,
            variant: parameters.variant.hmacVariant
        )
        return try Data(engine.calculate())
    }

    public var uniqueAlgorithmIdentifier: String {
        let parameters = [
            "keyLength=\(parameters.keyLength)",
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

        public var keyLength: Int
        public var variant: Variant

        public init(keyLength: Int, variant: Variant) {
            self.keyLength = keyLength
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
