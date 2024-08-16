import Foundation

/// A key that is generic over a specific bit length.
public struct KeyData<Length: KeyLength>: Equatable, Hashable, Sendable {
    public let data: Data

    public struct LengthError: Error {}

    public init(data: Data) throws {
        guard data.count == Length.bytes else { throw LengthError() }
        self.data = data
    }
}

extension KeyData: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(data: data)
    }
}

extension KeyData {
    public static var length: Int { Length.bytes }

    public static func zero() -> Self {
        .repeating(byte: 0x00)
    }

    public static func random() -> Self {
        // Force try: This is of the same length as the key, so it will not throw.
        try! .init(data: .random(count: length))
    }

    public static func repeating(byte: UInt8) -> Self {
        // Force try: This is of the same length as the key, so it will not throw.
        try! .init(data: Data(repeating: byte, count: length))
    }
}

// MARK: - KeyLength

public protocol KeyLength: Sendable {
    static var bytes: Int { get }
}

/// A key that is 256 bits (32 bytes) in length.
public struct Bits256: KeyLength {
    public static var bytes: Int { 32 }
}

/// A key that is 64 bits (8 bytes) in length.
public struct Bits64: KeyLength {
    public static var bytes: Int { 8 }
}
