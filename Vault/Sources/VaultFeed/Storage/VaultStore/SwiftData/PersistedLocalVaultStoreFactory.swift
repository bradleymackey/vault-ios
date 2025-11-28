import Foundation
import SwiftData

public final class PersistedLocalVaultStoreFactory {
    private let storageDirectory: URL

    public init(storageDirectory: URL) {
        self.storageDirectory = storageDirectory
    }

    public func makeVaultStore() -> PersistedLocalVaultStore {
        do {
            let storeURL = storageDirectory.appending(path: "vault-primary.sqlite")
            let configuration = ModelConfiguration(
                "PersistedLocalVaultStore",
                schema: .init(versionedSchema: PersistedSchemaLatestVersion.self),
                url: storeURL,
            )
            let container = try ModelContainer(
                for: PersistedVaultItem.self, PersistedVaultTag.self,
                migrationPlan: PersistedSchemaMigrationPlan.self,
                configurations: configuration,
            )
            return PersistedLocalVaultStore(modelContainer: container)
        } catch {
            fatalError("Unable to connect to PersistedLocalVaultStore: \(error)")
        }
    }

    struct NoUserDocumentDirectory: Error, LocalizedError {
        var errorDescription: String? {
            "No user document directory available"
        }
    }
}
