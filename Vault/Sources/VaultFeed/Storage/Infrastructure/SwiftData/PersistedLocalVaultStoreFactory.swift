import Foundation

public final class PersistedLocalVaultStoreFactory {
    private let fileManager: FileManager

    public init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    public func makeVaultStore() -> PersistedLocalVaultStore {
        do {
            let storeURL = try getDocumentDirectory().appending(path: "PersistedLocalVaultStore-Main")
            return try PersistedLocalVaultStore(configuration: .storedOnDisk(storeURL))
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
