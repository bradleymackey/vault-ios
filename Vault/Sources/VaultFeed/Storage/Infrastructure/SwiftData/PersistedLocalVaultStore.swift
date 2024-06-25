import Foundation
import SwiftData

/// Uses SwiftData with a CoreData backing layer to persist content.
///
/// Conforms to SwiftData's `ModelActor` to ensure all database operations are thread-safe.
@ModelActor
public final actor PersistedLocalVaultStore {
    public enum Error: Swift.Error {
        case modelNotFound
    }
}

// MARK: - VaultStoreReader

extension PersistedLocalVaultStore: VaultStoreReader {
    public func retrieve() async throws -> VaultRetrievalResult<VaultItem> {
        let always = VaultEncodingConstants.Visibility.always
        let predicate = #Predicate<PersistedVaultItem> {
            $0.visibility == always
        }
        let descriptor = FetchDescriptor<PersistedVaultItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.updatedDate)]
        )
        let results = try modelContext.fetch(descriptor)
        return .collectFrom(retrievedItems: results)
    }

    public func retrieve(matching query: String) async throws -> VaultRetrievalResult<VaultItem> {
        // NOTE: Compounding queries in SwiftData is a bit rough at the moment.
        // Each Predicate can only contain a single expression, so we must create them seperately
        // then compound them (a big chain of disjunctions leads to "expression too complex" errors).

        // It also really doesn't play well with Optional Chaining (it leads to internal SQL errors),
        // but flapMap works just fine.

        let full = VaultEncodingConstants.SearchableLevel.full
        let onlyTitle = VaultEncodingConstants.SearchableLevel.onlyTitle
        let onlyPassphrase = VaultEncodingConstants.SearchableLevel.onlyPassphrase
        let titleSearchable = #Predicate<PersistedVaultItem> {
            $0.searchableLevel == full || $0.searchableLevel == onlyTitle
        }

        let contentSearchable = #Predicate<PersistedVaultItem> {
            $0.searchableLevel == full
        }

        let passphrasePredicate = #Predicate<PersistedVaultItem> { item in
            item.searchableLevel == onlyPassphrase &&
                // We need an EXACT match on the passphrase
                item.searchPassphrase.flatMap { $0 == query } ?? false
        }

        let userDescriptionPredicate = #Predicate<PersistedVaultItem> {
            $0.userDescription.localizedStandardContains(query) && titleSearchable.evaluate($0)
        }

        let noteTitlePredicate = #Predicate<PersistedVaultItem> { item in
            item.noteDetails.flatMap {
                $0.title.localizedStandardContains(query) && titleSearchable.evaluate(item)
            } ?? false
        }

        let noteContentsPredicate = #Predicate<PersistedVaultItem> { item in
            item.noteDetails.flatMap {
                $0.contents.localizedStandardContains(query) && contentSearchable.evaluate(item)
            } ?? false
        }

        let codeNamePredicate = #Predicate<PersistedVaultItem> { item in
            item.otpDetails.flatMap {
                $0.accountName.localizedStandardContains(query) && titleSearchable.evaluate(item)
            } ?? false
        }

        let codeIssuerPredicate = #Predicate<PersistedVaultItem> { item in
            item.otpDetails.flatMap {
                $0.issuer.localizedStandardContains(query) && titleSearchable.evaluate(item)
            } ?? false
        }

        let predicate = #Predicate<PersistedVaultItem> {
            passphrasePredicate.evaluate($0) ||
                userDescriptionPredicate.evaluate($0) ||
                noteTitlePredicate.evaluate($0) ||
                noteContentsPredicate.evaluate($0) ||
                codeNamePredicate.evaluate($0) ||
                codeIssuerPredicate.evaluate($0)
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.updatedDate)])
        let results = try modelContext.fetch(descriptor)
        return .collectFrom(retrievedItems: results)
    }
}

extension VaultRetrievalResult where T == VaultItem {
    /// Decodes and collects `PersistedVaultItem` instances into a retrieval result.
    fileprivate static func collectFrom(retrievedItems: [PersistedVaultItem]) -> Self {
        let decoder = PersistedVaultItemDecoder()
        return retrievedItems.reduce(into: VaultRetrievalResult<VaultItem>()) { result, item in
            do {
                let decodedItem = try decoder.decode(item: item)
                result.items.append(decodedItem)
            } catch let error as VaultItemDecodingError {
                result.errors.append(.failedToDecode(error))
            } catch {
                result.errors.append(.unknown)
            }
        }
    }
}

// MARK: - VaultStoreWriter

extension PersistedLocalVaultStore: VaultStoreWriter {
    @discardableResult
    public func insert(item: VaultItem.Write) async throws -> UUID {
        do {
            let encoder = PersistedVaultItemEncoder(context: modelContext)
            let encoded = try encoder.encode(item: item)

            try modelContext.save()
            return encoded.id
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func update(id: UUID, item: VaultItem.Write) async throws {
        do {
            var descriptor = FetchDescriptor<PersistedVaultItem>(predicate: #Predicate { item in
                item.id == id
            })
            descriptor.fetchLimit = 1
            guard let existing = try modelContext.fetch(descriptor).first else {
                throw Error.modelNotFound
            }
            let encoder = PersistedVaultItemEncoder(context: modelContext)
            _ = try encoder.encode(item: item, existing: existing)

            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func delete(id: UUID) async throws {
        do {
            try modelContext.delete(model: PersistedVaultItem.self, where: #Predicate {
                $0.id == id
            })
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}

// MARK: - VaultStoreExporter

extension PersistedLocalVaultStore: VaultStoreExporter {
    public func exportVault(userDescription: String) async throws -> VaultApplicationPayload {
        let allItemsDescriptor = FetchDescriptor<PersistedVaultItem>(predicate: #Predicate { _ in true })
        let allItems = try modelContext.fetch(allItemsDescriptor)
        let allTagsDescriptor = FetchDescriptor<PersistedVaultTag>(predicate: #Predicate { _ in true })
        let allTags = try modelContext.fetch(allTagsDescriptor)
        let itemDecoder = PersistedVaultItemDecoder()
        let tagDecoder = PersistedVaultTagDecoder()
        return try .init(
            userDescription: userDescription,
            items: allItems.map {
                try itemDecoder.decode(item: $0)
            },
            tags: allTags.map {
                try tagDecoder.decode(item: $0)
            }
        )
    }
}
