internal import CryptoSwift
import Foundation
import FoundationExtensions

/// Derives keys using the *scrypt* algorithm.
///
/// https://en.wikipedia.org/wiki/Scrypt
public struct ScryptKeyDeriver<Length: KeyLength>: KeyDeriver {
    public let parameters: Parameters

    public init(parameters: Parameters) {
        self.parameters = parameters
    }

    public func key(password: Data, salt: Data) throws -> KeyData<Length> {
        let engine = try Scrypt(
            password: password.byteArray,
            salt: salt.byteArray,
            dkLen: Length.bytes,
            N: parameters.costFactor,
            r: parameters.blockSizeFactor,
            p: parameters.parallelizationFactor,
        )
        let data = try Data(engine.calculate())
        return try KeyData(data: data)
    }

    public var uniqueAlgorithmIdentifier: String {
        let parameters = [
            "keyLength=\(Length.bytes)",
            "costFactor=\(parameters.costFactor)",
            "blockSizeFactor=\(parameters.blockSizeFactor)",
            "parallelizationFactor=\(parameters.parallelizationFactor)",
        ]
        let parameterDescription = parameters.joined(separator: ";")
        return "SCRYPT<\(parameterDescription)>"
    }
}

// MARK: - Parameters

extension ScryptKeyDeriver {
    public struct Parameters: Sendable {
        /// **N**
        ///
        /// CPU/memory cost parameter – Must be a power of 2 (e.g. 1024)
        public var costFactor: Int
        /// **r**
        ///
        /// blocksize parameter, which fine-tunes sequential memory read size and performance. (8 is commonly used)
        public var blockSizeFactor: Int
        /// **p**
        ///
        /// Parallelization parameter. (1 .. 232-1 * hLen/MFlen)
        public var parallelizationFactor: Int

        public init(costFactor: Int, blockSizeFactor: Int, parallelizationFactor: Int) {
            self.costFactor = costFactor
            self.blockSizeFactor = blockSizeFactor
            self.parallelizationFactor = parallelizationFactor
        }
    }
}
