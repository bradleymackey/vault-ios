import Foundation
import FoundationExtensions

public struct VaultItemTag: Identifiable, Sendable, Equatable, Hashable {
    /// Static identifier for this item
    public let id: Identifier<VaultItemTag>
    public var name: String
    public var color: VaultItemColor?
    public var iconName: String?

    public init(id: Identifier<VaultItemTag>, name: String, color: VaultItemColor? = nil, iconName: String? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.iconName = iconName
    }

    /// The default system icon name that should be used by a tag.
    public static var defaultIconName: String {
        "tag.fill"
    }

    /// Maps this object to a `VaultItemTag.Write` for writing.
    ///
    /// This discards any non-deterministic data and identifiable information.
    public func makeWritable() -> VaultItemTag.Write {
        .init(name: name, color: color, iconName: iconName)
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
