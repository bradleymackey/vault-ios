import Foundation
internal import CryptoSwift

/// Produces hashes of data.
public struct Hasher {
    public init() {}

    public func sha256<T: Digestable>(value: T) throws -> Digest<T>.SHA256 {
        let encoded = try hashEncoder().encode(value.digestableData)
        let bytes = SHA2(variant: .sha256).calculate(for: encoded.bytes)
        return .init(value: Data(bytes))
    }
}

extension Hasher {
    /// A hasher that will consistently hash data given a particular input.
    private func hashEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.sortedKeys] // we need a consistent output
        encoder.keyEncodingStrategy = .useDefaultKeys
        return encoder
    }
}
