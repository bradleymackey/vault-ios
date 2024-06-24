import Foundation

public struct VaultRetrievalResult: Equatable, Sendable {
    public var items: [VaultItem]
    public var errors: [Error]

    public init(items: [VaultItem] = [], errors: [Error] = []) {
        self.items = items
        self.errors = errors
    }
}

extension VaultRetrievalResult {
    /// Reports any errors whilst retrieving items.
    public enum Error: Equatable, Sendable {
        case failedToDecode(VaultItemDecodingError)
        case unknown
    }

    public var errorCount: Int {
        errors.count
    }

    public var totalItems: Int {
        items.count + errors.count
    }
}

extension VaultRetrievalResult {
    public static func empty() -> VaultRetrievalResult {
        .init()
    }
}
