import Foundation
internal import CryptoSwift

public struct PBKDF2KeyDeriver: KeyDeriver {
    public let parameters: Parameters

    init(parameters: Parameters) {
        self.parameters = parameters
    }

    public func key(password: Data, salt: Data) async throws -> Data {
        let engine = try PKCS5.PBKDF2(
            password: password.bytes,
            salt: salt.bytes,
            iterations: parameters.iterations,
            keyLength: parameters.keyLength,
            variant: parameters.variant.hmacVariant
        )
        return try await computeOnBackgroundThread {
            try Data(engine.calculate())
        }
    }
}

// MARK: - Parameters

extension PBKDF2KeyDeriver {
    public struct Parameters {
        public enum Variant: Equatable {
            case sha384
        }

        public var keyLength: Int
        public var iterations: Int
        public var variant: Variant

        public init(keyLength: Int, iterations: Int, variant: Variant) {
            self.keyLength = keyLength
            self.iterations = iterations
            self.variant = variant
        }
    }
}

extension PBKDF2KeyDeriver.Parameters.Variant {
    fileprivate var hmacVariant: HMAC.Variant {
        switch self {
        case .sha384: .sha2(.sha384)
        }
    }
}
