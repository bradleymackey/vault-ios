import CoreData
import OTPCore

public class CoreDataCodeStore {
    public static let modelName = "OTPStore"
    public static let model = NSManagedObjectModel.with(name: modelName, in: .module)

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    enum StoreError: Error {
        case modelNotFound
        case failedToLoadPersistentContainer
    }

    public init(storeURL: URL) throws {
        guard let model = CoreDataCodeStore.model else {
            throw StoreError.modelNotFound
        }
        do {
            container = try NSPersistentContainer.load(name: CoreDataCodeStore.modelName, model: model, url: storeURL)
            context = container.newBackgroundContext()
        } catch {
            throw StoreError.failedToLoadPersistentContainer
        }
    }

    public func retrieve() async throws -> [OTPAuthCode] {
        try await withCheckedThrowingContinuation { cont in
            context.perform {
                do {
                    let results = try ManagedOTPCode.fetchAll(in: self.context)
                    cont.resume(returning: results.map { _ in
                        OTPAuthCode(
                            secret: .empty(),
                            accountName: "any"
                        )
                    })
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }
}

extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        bundle
            .url(forResource: name, withExtension: "momd")
            .flatMap {
                NSManagedObjectModel(contentsOf: $0)
            }
    }
}

extension NSPersistentContainer {
    static func load(name: String, model: NSManagedObjectModel, url: URL) throws -> NSPersistentContainer {
        let description = NSPersistentStoreDescription(url: url)
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [description]

        var loadError: Swift.Error?
        container.loadPersistentStores { loadError = $1 }
        try loadError.map { throw $0 }

        return container
    }
}
