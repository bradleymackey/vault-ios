import Foundation

public struct Key256Bit: Equatable, Hashable, Sendable {
    public let data: Data

    public struct LengthError: Error {}

    public init(data: Data) throws {
        guard data.count == Self.length else { throw LengthError() }
        self.data = data
    }
}

extension Key256Bit {
    public static var length: Int { 32 }

    public static func random() -> Self {
        // Force try: This is of the same length as the key, so it will not throw.
        try! .init(data: .random(count: length))
    }

    public static func repeating(byte: UInt8) -> Self {
        // Force try: This is of the same length as the key, so it will not throw.
        try! .init(data: Data(repeating: byte, count: length))
    }
}
