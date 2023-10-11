import CoreData
import Foundation
import XCTest
@testable import VaultFeed

extension NSPersistentContainer {
    /// Create an in-memory container for testing, using the model store defined in `CoreDataVaultStore`.
    static func testContainer(storeName: String) throws -> NSPersistentContainer {
        try NSPersistentContainer.load(
            name: CoreDataVaultStore.modelName,
            model: XCTUnwrap(CoreDataVaultStore.model),
            url: inMemoryStoreURL(storeName: storeName)
        )
    }

    private static func inMemoryStoreURL(storeName: String) -> URL {
        URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(storeName).store")
    }
}
