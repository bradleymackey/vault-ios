internal import CryptoSwift
import Foundation

/// Derives keys using the *scrypt* algorithm.
///
/// https://en.wikipedia.org/wiki/Scrypt
public struct ScryptKeyDeriver: KeyDeriver {
    public let parameters: Parameters

    public init(parameters: Parameters) {
        self.parameters = parameters
    }

    /// Generate a the key using the provided data and parameters.
    ///
    /// Key generation is expensive, so this will asynchronously run on a background thread to avoid blocking the
    /// current thread.
    public func key(password: Data, salt: Data) throws -> Data {
        let engine = try Scrypt(
            password: password.bytes,
            salt: salt.bytes,
            dkLen: parameters.keyLength,
            N: parameters.costFactor,
            r: parameters.blockSizeFactor,
            p: parameters.parallelizationFactor
        )
        return try Data(engine.calculate())
    }

    public var uniqueAlgorithmIdentifier: String {
        let parameters = [
            "keyLength=\(parameters.keyLength)",
            "costFactor=\(parameters.costFactor)",
            "blockSizeFactor=\(parameters.blockSizeFactor)",
            "parallelizationFactor=\(parameters.blockSizeFactor)",
        ]
        let parameterDescription = parameters.joined(separator: ";")
        return "SCRYPT<\(parameterDescription)>"
    }
}

// MARK: - Parameters

extension ScryptKeyDeriver {
    public struct Parameters {
        /// **dkLen**
        ///
        /// Desired key length in bytes (Intended output length in octets of the derived key; a positive integer
        /// satisfying dkLen ≤ (232− 1) * hLen.)
        public var keyLength: Int
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

        public init(keyLength: Int, costFactor: Int, blockSizeFactor: Int, parallelizationFactor: Int) {
            self.keyLength = keyLength
            self.costFactor = costFactor
            self.blockSizeFactor = blockSizeFactor
            self.parallelizationFactor = parallelizationFactor
        }
    }
}
