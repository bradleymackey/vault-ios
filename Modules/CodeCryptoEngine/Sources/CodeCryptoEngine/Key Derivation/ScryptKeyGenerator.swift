import CryptoSwift
import Foundation

/// A key generator, generating a 256-bit key using Scrypt.
public struct ScryptKeyGenerator {
    private let engine: Scrypt
    public let parameters: Parameters

    public init(password: Data, salt: Data, parameters: Parameters) throws {
        self.parameters = parameters
        engine = try Scrypt(
            password: password.bytes,
            salt: salt.bytes,
            dkLen: parameters.outputLengthBytes,
            N: parameters.costFactor,
            r: parameters.blockSizeFactor,
            p: parameters.parallelizationFactor
        )
    }

    public func key() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(with: Result {
                    try Data(engine.calculate())
                })
            }
        }
    }
}

// MARK: - Parameters

public extension ScryptKeyGenerator {
    struct Parameters {
        /// **dkLen**
        ///
        /// Desired key length in bytes (Intended output length in octets of the derived key; a positive integer satisfying dkLen ≤ (232− 1) * hLen.)
        public var outputLengthBytes: Int
        /// **N**
        ///
        /// CPU/memory cost parameter – Must be a power of 2 (e.g. 1024)
        public var costFactor: Int
        /// **r**
        ///
        /// blocksize parameter, which fine-tunes sequential memory read size and performance. (8 is commonly used)
        public var blockSizeFactor: Int
        ///
        ///
        /// Parallelization parameter. (1 .. 232-1 * hLen/MFlen)
        public var parallelizationFactor: Int

        public init(outputLengthBytes: Int, costFactor: Int, blockSizeFactor: Int, parallelizationFactor: Int) {
            self.outputLengthBytes = outputLengthBytes
            self.costFactor = costFactor
            self.blockSizeFactor = blockSizeFactor
            self.parallelizationFactor = parallelizationFactor
        }
    }
}

public extension ScryptKeyGenerator.Parameters {
    static var aes256Strong: Self {
        .init(
            outputLengthBytes: 32,
            costFactor: 16384,
            blockSizeFactor: 8,
            parallelizationFactor: 1
        )
    }
}
