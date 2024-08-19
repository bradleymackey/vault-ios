import Foundation
internal import CryptoSwift

/// Produces hashes of data.
public struct Hasher {
    public init() {}

    public func sha256<T: Encodable>(value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let encoded = try encoder.encode(value)
        let bytes = SHA2(variant: .sha256).calculate(for: encoded.bytes)
        return Data(bytes)
    }
}
