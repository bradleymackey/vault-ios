import Foundation
import SwiftData

/// Uses SwiftData with a CoreData backing layer to persist content.
public final actor PersistedLocalVaultStore {
    private let container: ModelContainer
    private let context: ModelContext

    public enum Error: Swift.Error {
        case modelNotFound
    }

    public enum Configuration: Sendable {
        case inMemory
        case storedOnDisk(URL)

        fileprivate var modelConfiguration: ModelConfiguration {
            switch self {
            case .inMemory: .init(isStoredInMemoryOnly: true)
            case let .storedOnDisk(url): .init(url: url)
            }
        }
    }

    public init(configuration: Configuration) throws {
        container = try .init(
            for: PersistedVaultItem.self,
            migrationPlan: nil,
            configurations: configuration.modelConfiguration
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
        let always = VaultEncodingConstants.Visibility.always
        let predicate = #Predicate<PersistedVaultItem> {
            $0.visibility == always
        }
        let descriptor = FetchDescriptor<PersistedVaultItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.updatedDate)]
        )
        let results = try context.fetch(descriptor)
        let decoder = PersistedVaultItemDecoder()
        return try results.map {
            try decoder.decode(item: $0)
        }
    }

    public func retrieve(matching query: String) async throws -> [StoredVaultItem] {
        // NOTE: Compounding queries in SwiftData is a bit rough at the moment.
        // Each Predicate can only contain a single expression, so we must create them seperately
        // then compound them (a big chain of disjunctions leads to "expression too complex" errors).

        // It also really doesn't play well with Optional Chaining (it leads to internal SQL errors),
        // but flapMap works just fine.

        let userDescriptionPredicate = #Predicate<PersistedVaultItem> {
            $0.userDescription.localizedStandardContains(query)
        }

        let noteTitlePredicate = #Predicate<PersistedVaultItem> {
            $0.noteDetails.flatMap {
                $0.title.localizedStandardContains(query)
            } ?? false
        }

        let noteContentsPredicate = #Predicate<PersistedVaultItem> {
            $0.noteDetails.flatMap {
                $0.contents.localizedStandardContains(query)
            } ?? false
        }

        let codeNamePredicate = #Predicate<PersistedVaultItem> {
            $0.otpDetails.flatMap {
                $0.accountName.localizedStandardContains(query)
            } ?? false
        }

        let codeIssuerPredicate = #Predicate<PersistedVaultItem> {
            $0.otpDetails.flatMap {
                $0.issuer.localizedStandardContains(query)
            } ?? false
        }

        let predicate = #Predicate<PersistedVaultItem> {
            userDescriptionPredicate.evaluate($0) ||
                noteTitlePredicate.evaluate($0) ||
                noteContentsPredicate.evaluate($0) ||
                codeNamePredicate.evaluate($0) ||
                codeIssuerPredicate.evaluate($0)
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.updatedDate)])
        let results = try context.fetch(descriptor)
        let decoder = PersistedVaultItemDecoder()
        return try results.map {
            try decoder.decode(item: $0)
        }
    }
}

// MARK: - VaultStoreWriter

extension PersistedLocalVaultStore: VaultStoreWriter {
    @discardableResult
    public func insert(item: StoredVaultItem.Write) async throws -> UUID {
        do {
            let encoder = PersistedVaultItemEncoder(context: context)
            let encoded = encoder.encode(item: item)

            try context.save()
            return encoded.id
        } catch {
            context.rollback()
            throw error
        }
    }

    public func update(id: UUID, item: StoredVaultItem.Write) async throws {
        do {
            var descriptor = FetchDescriptor<PersistedVaultItem>(predicate: #Predicate { item in
                item.id == id
            })
            descriptor.fetchLimit = 1
            guard let existing = try context.fetch(descriptor).first else {
                throw Error.modelNotFound
            }
            let encoder = PersistedVaultItemEncoder(context: context)
            _ = encoder.encode(item: item, existing: existing)

            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    public func delete(id: UUID) async throws {
        do {
            try context.delete(model: PersistedVaultItem.self, where: #Predicate {
                $0.id == id
            })
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
