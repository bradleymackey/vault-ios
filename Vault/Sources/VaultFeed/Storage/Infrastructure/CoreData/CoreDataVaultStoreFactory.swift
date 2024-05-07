import Foundation

/// Creates a `CoreDataVaultStore` with assertions that the vault actually exists.
public final class CoreDataVaultStoreFactory {
    private let fileManager: FileManager

    public init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    public func makeVaultStore() -> CoreDataVaultStore {
        let storeURL = getDocumentDirectory().appending(path: "vault")
        do {
            return try CoreDataVaultStore(storeURL: storeURL)
        } catch {
            fatalError("Unable to create vault store at \(storeURL)")
        }
    }

    private func getDocumentDirectory() -> URL {
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("There is no user document directory")
        }
        return documentDirectory
    }
}
