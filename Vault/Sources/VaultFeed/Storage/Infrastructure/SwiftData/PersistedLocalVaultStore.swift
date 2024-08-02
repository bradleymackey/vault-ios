import Foundation
import FoundationExtensions
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
    public func retrieve(query: VaultStoreQuery) async throws -> VaultRetrievalResult<VaultItem> {
        let descriptor = FetchDescriptor<PersistedVaultItem>(
            predicate: makePredicate(query: query),
            sortBy: [SortDescriptor(\.updatedDate)]
        )
        let results = try modelContext.fetch(descriptor)
        return .collectFrom(retrievedItems: results)
    }

    /// Creates a predicate that returns items when querying.
    private func makePredicate(query: VaultStoreQuery) -> Predicate<PersistedVaultItem> {
        let tagsPredicate = makeTagsPredicate(matchingTags: query.tags)
        if let searchText = query.searchText, searchText.isNotEmpty {
            // (1) Searching by text and (2) filtering by tags.
            // We don't need to filter by visibility level since all items should appear.

            let searchPredicate = makeSearchTextPredicate(matchingText: searchText)
            return #Predicate<PersistedVaultItem> {
                searchPredicate.evaluate($0) && tagsPredicate.evaluate($0)
            }
        } else {
            // Only filtering by tags.
            // We need to explicitly filter by items that are "always visible", since the user is not searching.

            let always = VaultEncodingConstants.Visibility.always
            let visibilityPredicate = #Predicate<PersistedVaultItem> {
                $0.visibility == always
            }
            return #Predicate<PersistedVaultItem> {
                visibilityPredicate.evaluate($0) &&
                    tagsPredicate.evaluate($0)
            }
        }
    }

    private func makeTagsPredicate(matchingTags tags: Set<Identifier<VaultItemTag>>) -> Predicate<PersistedVaultItem> {
        if tags.isEmpty {
            // We're not filtering by any tags, so don't check tags.
            return .true
        } else {
            let tagUUIDs = tags.map(\.id).reducedToSet()
            return #Predicate<PersistedVaultItem> { item in
                item.tags.contains(where: { tagUUIDs.contains($0.id) })
            }
        }
    }

    private func makeSearchTextPredicate(matchingText query: String) -> Predicate<PersistedVaultItem> {
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

        // Can only search full content if searchable level is full AND the item isn't locked.
        // If it's locked, we shouldn't be able to search the content.
        let notLocked = VaultEncodingConstants.LockState.notLocked
        let contentSearchable = #Predicate<PersistedVaultItem> {
            $0.searchableLevel == full && $0.lockState == notLocked
        }

        let orderedSame = ComparisonResult.orderedSame
        let passphrasePredicate = #Predicate<PersistedVaultItem> { item in
            item.searchableLevel == onlyPassphrase &&
                // We need an EXACT match on the passphrase (case insensitive)
                item.searchPassphrase.flatMap {
                    $0.caseInsensitiveCompare(query) == orderedSame
                } ?? false
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

        return #Predicate<PersistedVaultItem> {
            passphrasePredicate.evaluate($0) ||
                userDescriptionPredicate.evaluate($0) ||
                noteTitlePredicate.evaluate($0) ||
                noteContentsPredicate.evaluate($0) ||
                codeNamePredicate.evaluate($0) ||
                codeIssuerPredicate.evaluate($0)
        }
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
    public func insert(item: VaultItem.Write) async throws -> Identifier<VaultItem> {
        do {
            let encoder = PersistedVaultItemEncoder(context: modelContext)
            let encoded = try encoder.encode(item: item)

            try modelContext.save()
            return Identifier(id: encoded.id)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func update(id: Identifier<VaultItem>, item: VaultItem.Write) async throws {
        do {
            let uuid = id.rawValue
            var descriptor = FetchDescriptor<PersistedVaultItem>(predicate: #Predicate { item in
                item.id == uuid
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

    public func delete(id: Identifier<VaultItem>) async throws {
        do {
            let uuid = id.rawValue
            try modelContext.delete(model: PersistedVaultItem.self, where: #Predicate {
                $0.id == uuid
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
        let allItems: [PersistedVaultItem] = try modelContext.fetch(.all())
        let allTags: [PersistedVaultTag] = try modelContext.fetch(.all())
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

// MARK: - VaultTagStoreReader

extension PersistedLocalVaultStore: VaultTagStoreReader {
    public func retrieveTags() async throws -> [VaultItemTag] {
        let allTags: [PersistedVaultTag] = try modelContext.fetch(.all(sortBy: [SortDescriptor(\.title)]))
        let decoder = PersistedVaultTagDecoder()
        return try allTags.map {
            try decoder.decode(item: $0)
        }
    }
}

// MARK: - VaultTagStoreWriter

extension PersistedLocalVaultStore: VaultTagStoreWriter {
    @discardableResult
    public func insertTag(item: VaultItemTag.Write) async throws -> Identifier<VaultItemTag> {
        do {
            let encoder = PersistedVaultTagEncoder(context: modelContext)
            let newTag = encoder.encode(tag: item)

            try modelContext.save()
            return Identifier<VaultItemTag>(id: newTag.id)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func updateTag(id: Identifier<VaultItemTag>, item: VaultItemTag.Write) async throws {
        do {
            let uuid = id.id
            var descriptor = FetchDescriptor<PersistedVaultTag>(predicate: #Predicate { item in
                item.id == uuid
            })
            descriptor.fetchLimit = 1
            guard let existing = try modelContext.fetch(descriptor).first else {
                throw Error.modelNotFound
            }
            let encoder = PersistedVaultTagEncoder(context: modelContext)
            _ = encoder.encode(tag: item, existing: existing)

            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func deleteTag(id: Identifier<VaultItemTag>) async throws {
        do {
            let uuid = id.id
            try modelContext.delete(model: PersistedVaultTag.self, where: #Predicate {
                $0.id == uuid
            })
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
