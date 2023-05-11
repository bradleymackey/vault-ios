import CoreData
import Foundation
import XCTest
@testable import OTPFeed

extension NSPersistentContainer {
    /// Create an in-memory container for testing, using the model store defined in `CoreDataCodeStore`.
    static func testContainer(storeName: String) throws -> NSPersistentContainer {
        try NSPersistentContainer.load(
            name: CoreDataCodeStore.modelName,
            model: XCTUnwrap(CoreDataCodeStore.model),
            url: inMemoryStoreURL(storeName: storeName)
        )
    }

    private static func inMemoryStoreURL(storeName: String) -> URL {
        URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(storeName).store")
    }
}
