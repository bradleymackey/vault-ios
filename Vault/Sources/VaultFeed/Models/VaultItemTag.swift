import CryptoEngine
import Foundation
import FoundationExtensions

public struct VaultItemTag: Identifiable, Sendable, Equatable, Hashable {
    /// Static identifier for this item
    public let id: Identifier<VaultItemTag>
    public var name: String
    public var color: VaultItemColor
    public var iconName: String

    public init(
        id: Identifier<VaultItemTag>,
        name: String,
        color: VaultItemColor = .tagDefault,
        iconName: String = Self.defaultIconName,
    ) {
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

    /// Make the write update context when importing data.
    public func makeImportingContext() -> VaultItemTag.WriteUpdateContext {
        .init(id: id)
    }
}

extension VaultItemTag: Digestable {
    public var digestableData: some Encodable {
        struct DigestData: Encodable {
            var id: UUID
            var name: String
            var iconName: String
        }
        return DigestData(id: id.id, name: name, iconName: iconName)
    }
}

// MARK: - Write

extension VaultItemTag {
    public struct Write: Equatable, Sendable {
        public var name: String
        public var color: VaultItemColor
        public var iconName: String

        public init(name: String, color: VaultItemColor, iconName: String) {
            self.name = name
            self.color = color
            self.iconName = iconName
        }
    }

    /// Writable data used when importing or updating, we we have known values for these
    /// existing fields.
    public struct WriteUpdateContext: Sendable {
        public var id: Identifier<VaultItemTag>

        public init(id: Identifier<VaultItemTag>) {
            self.id = id
        }
    }
}

extension VaultItemTag.Write {
    public static func new() -> Self {
        .init(name: "", color: .tagDefault, iconName: VaultItemTag.defaultIconName)
    }
}
