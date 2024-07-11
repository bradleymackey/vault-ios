import Foundation

public struct VaultItemTag: Identifiable, Sendable {
    /// Uniquely identifies this tag.
    public struct Identifier: Identifiable, Equatable, Hashable, Sendable {
        public let id: UUID

        public init(id: UUID) {
            self.id = id
        }
    }

    /// Static identifier for this item
    public let id: Identifier
    public var name: String
    public var color: VaultItemColor?
    public var iconName: String?

    public init(id: Identifier, name: String, color: VaultItemColor? = nil, iconName: String? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.iconName = iconName
    }

    public var asWritable: VaultItemTag.Write {
        .init(name: name, color: color, iconName: iconName)
    }
}

extension VaultItemTag: Equatable, Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Write

extension VaultItemTag {
    public struct Write: Equatable, Sendable {
        public var name: String
        public var color: VaultItemColor?
        public var iconName: String?

        public init(name: String, color: VaultItemColor?, iconName: String?) {
            self.name = name
            self.color = color
            self.iconName = iconName
        }
    }
}
