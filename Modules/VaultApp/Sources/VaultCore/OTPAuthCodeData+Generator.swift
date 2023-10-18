import CryptoEngine
import Foundation

extension OTPAuthCodeData {
    /// Create an `HOTPGenerator` from this code, initalized with the current parameters of the code.
    public func hotpGenerator() -> HOTPGenerator {
        HOTPGenerator(secret: secret.data, digits: digits.value, algorithm: hotpAlgorithm)
    }

    private var hotpAlgorithm: HOTPGenerator.Algorithm {
        switch algorithm {
        case .sha1:
            .sha1
        case .sha256:
            .sha256
        case .sha512:
            .sha512
        }
    }
}
