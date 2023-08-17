import CryptoEngine
import Foundation

extension OTPAuthCodeData {
    /// Create an `HOTPGenerator` from this code, initalized with the current parameters of the code.
    public func hotpGenerator() -> HOTPGenerator {
        HOTPGenerator(secret: secret.data, digits: hotpDigits, algorithm: hotpAlgorithm)
    }

    private var hotpDigits: HOTPGenerator.Digits {
        switch digits {
        case .six:
            return .six
        case .seven:
            return .seven
        case .eight:
            return .eight
        }
    }

    private var hotpAlgorithm: HOTPGenerator.Algorithm {
        switch algorithm {
        case .sha1:
            return .sha1
        case .sha256:
            return .sha256
        case .sha512:
            return .sha512
        }
    }
}
