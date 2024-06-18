import Foundation
import SwiftData

/// Uses SwiftData with a CoreData backing layer to persist content.
public final actor PersistedLocalVaultStore {
    private let container: ModelContainer
    private let context: ModelContext

    public init(storeURL: URL) throws {
        container = try .init(
            for: PersistedVaultItem.self,
            migrationPlan: nil,
            configurations: .init(url: storeURL)
        )
        context = .init(container)
    }

    @MainActor
    public var mainContext: ModelContext {
        container.mainContext
    }

    public func makeContext() -> ModelContext {
        .init(container)
    }
}

// MARK: - VaultStoreReader

extension PersistedLocalVaultStore: VaultStoreReader {
    public func retrieve() async throws -> [StoredVaultItem] {
        let results = try PersistedVaultItem.fetchAll(in: context)
        // TODO: map items
        return []
    }

    public func retrieve(matching query: String) async throws -> [StoredVaultItem] {
        let results = try PersistedVaultItem.fetch(matchingQuery: query, in: context)
        // TODO: map items
        return []
    }
}
