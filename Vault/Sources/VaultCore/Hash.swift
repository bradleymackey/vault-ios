import CryptoEngine
import Foundation

/// Namespace for hash types.
///
/// Hashes are strongly-typed to a particular model.
public enum Hash<T> {}

extension Hash {
    public struct SHA256: Hashable, Equatable, Sendable {
        public let value: Data

        public init(value: Data) {
            self.value = value
        }

        public static func makeHash(_ value: T) throws -> Self where T: Encodable {
            let hasher = Hasher()
            let data = try hasher.sha256(value: value)
            return .init(value: data)
        }
    }
}

extension Hash.SHA256: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Data.self)
    }
}
