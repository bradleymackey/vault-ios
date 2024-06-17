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
}
