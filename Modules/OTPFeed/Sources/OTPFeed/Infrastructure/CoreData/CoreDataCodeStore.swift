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

    public func insert(code: OTPAuthCode) async throws {
        try await asyncPerform { context in
            do {
                let encoder = ManagedOTPCodeEncoder(context: context)
                _ = encoder.encode(code: code)

                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    public func retrieve() async throws -> [OTPAuthCode] {
        try await asyncPerform { context in
            let results = try ManagedOTPCode.fetchAll(in: context)
            let decoder = ManagedOTPCodeDecoder()
            return try results.map { managedCode in
                try decoder.decode(code: managedCode)
            }
        }
    }

    /// Helper for asynchronously performing a block of CoreData work
    private func asyncPerform<T>(closure: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                continuation.resume(with: Result {
                    try closure(self.context)
                })
            }
        }
    }
}
