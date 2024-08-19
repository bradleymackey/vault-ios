import Foundation

public enum Hash {}

extension Hash {
    public struct SHA256: Hashable, Equatable, Sendable {
        public let value: String

        public init(value: String) {
            self.value = value
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
        value = try container.decode(String.self)
    }
}
