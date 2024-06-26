import Foundation

public struct VaultApplicationPayload: Sendable {
    public var userDescription: String
    public var items: [VaultItem]
    public var tags: [VaultItemTag]
}
