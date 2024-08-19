import Foundation
import SwiftData

public final class PersistedLocalVaultStoreFactory {
    private let fileManager: FileManager

    public init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    public func makeVaultStore() -> PersistedLocalVaultStore {
        do {
            let storeURL = try getDocumentDirectory().appending(path: "PersistedLocalVaultStore-Main")
            let configuration = ModelConfiguration(
                "PersistedLocalVaultStore",
                schema: .init(versionedSchema: PersistedSchemaLatestVersion.self),
                url: storeURL
            )
            let container = try ModelContainer(
                for: PersistedVaultItem.self, PersistedVaultTag.self,
                migrationPlan: PersistedSchemaMigrationPlan.self,
                configurations: configuration
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

    private func getDocumentDirectory() throws -> URL {
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            return documentDirectory
        } else {
            throw NoUserDocumentDirectory()
        }
    }
}
