import Foundation

public struct Identifier<T>: Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID

    public init(id: UUID = UUID()) {
        self.id = id
    }
}

extension Identifier: RawRepresentable {
    public typealias RawValue = UUID

    public init?(rawValue: UUID) {
        self.init(id: rawValue)
    }

    public var rawValue: UUID {
        id
    }
}

// MARK: - Helpers

extension Identifier {
    public static func new() -> Self {
        .init(id: UUID())
    }
}
