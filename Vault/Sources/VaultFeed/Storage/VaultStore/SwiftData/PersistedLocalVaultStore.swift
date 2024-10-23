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
        case relativeItemNotFound
        case invalidItem
    }

    /// The sort order used by this store.
    ///
    /// This must be consistent for the lifetime of the store and application.
    /// It is how items in the store are fetched and what reorders are performed against.
    /// A change in this will affect the user-percieved order of their items.
    var sortOrder: VaultStoreSortOrder = .relativeOrder
}

// MARK: - VaultStoreReader

extension PersistedLocalVaultStore: VaultStoreReader {
    public var hasAnyItems: Bool {
        get async throws {
            try fetchHasModelsInStorage(model: PersistedVaultItem.self)
        }
    }

    public func retrieve(query: VaultStoreQuery) async throws -> VaultRetrievalResult<VaultItem> {
        let descriptor = FetchDescriptor<PersistedVaultItem>(
            predicate: makePredicate(query: query),
            sortBy: sortOrder.vaultItemSortDescriptors
        )
        let results = try modelContext.fetch(descriptor)
        return .collectFrom(retrievedItems: results)
    }

    /// Creates a predicate that returns items when querying.
    private func makePredicate(query: VaultStoreQuery) -> Predicate<PersistedVaultItem> {
        let tagsPredicate = makeTagsPredicate(matchingTags: query.filterTags)
        if let filterText = query.filterText, filterText.isNotEmpty {
            // (1) Searching by text and (2) filtering by tags.
            // We don't need to filter by visibility level since all items should appear.

            let searchPredicate = makeSearchTextPredicate(matchingText: filterText)
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
            let searchingTagIds = tags.map(\.id).reducedToSet()
            // Returns the number of tags matched by this item.
            let tagsMatchingSearch = #Expression<PersistedVaultItem, Int> { item in
                item.tags.filter { tag in
                    searchingTagIds.contains(tag.id)
                }.count
            }
            // Performs an "AND" query by checking if the number of tags matched equals
            // the number of tags we are searching for.
            let searchingTagsCount = searchingTagIds.count
            return #Predicate<PersistedVaultItem> { item in
                tagsMatchingSearch.evaluate(item) == searchingTagsCount
            }
        }
    }

    private func makeSearchTextPredicate(matchingText query: String) -> Predicate<PersistedVaultItem> {
        // Compounding queries in SwiftData is a bit rough at the moment.
        // Each Predicate can only contain a single expression, so we must create them seperately
        // then compound them (a big chain of disjunctions leads to "expression too complex" errors).
        //
        // ** SLOW COMPILE TIMES? **
        // Use a MAX of 2 expressions per predicate, or it could lead to EXPONENTIAL compile time increases.
        //
        // ** CRASHES AT RUNTIME DUE TO SQLITE ERRORS? **
        //  - Optional chaining does not seem to work, use `flatMap`.
        //  - Only compare LOCAL CONSTANTS, create local variables outside the predicate then compare those.
        //  - Stick to the supported operators inside of #Predicate, not everything works, even things you would expect.
        //

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

        let matchesMetadata = #Predicate<PersistedVaultItem> {
            passphrasePredicate.evaluate($0) ||
                userDescriptionPredicate.evaluate($0)
        }

        let matchesNote = #Predicate<PersistedVaultItem> {
            noteTitlePredicate.evaluate($0) ||
                noteContentsPredicate.evaluate($0)
        }

        let matchesCode = #Predicate<PersistedVaultItem> {
            codeNamePredicate.evaluate($0) ||
                codeIssuerPredicate.evaluate($0)
        }

        let matchesItem = #Predicate<PersistedVaultItem> {
            matchesCode.evaluate($0) || matchesNote.evaluate($0)
        }

        return #Predicate<PersistedVaultItem> {
            matchesMetadata.evaluate($0) || matchesItem.evaluate($0)
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
            modelContext.insert(encoded)

            try modelContext.save()
            return Identifier(id: encoded.id)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func update(id: Identifier<VaultItem>, item: VaultItem.Write) async throws {
        do {
            let existing = try fetchVaultItem(id: id)
            let encoder = PersistedVaultItemEncoder(context: modelContext)
            let item = try encoder.encode(item: item, existing: existing)
            modelContext.insert(item)

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

// MARK: - VaultStoreHOTPIncrementer

extension PersistedLocalVaultStore: VaultStoreHOTPIncrementer {
    public func incrementCounter(id: Identifier<VaultItem>) async throws {
        do {
            let existing = try fetchVaultItem(id: id)
            guard let otpDetails = existing.otpDetails else { throw Error.invalidItem }
            otpDetails.counter.safeIncrement()
            modelContext.insert(otpDetails)

            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}

extension Int64? {
    fileprivate mutating func safeIncrement() {
        switch self {
        case nil: break
        case let .some(val): self = val + 1
        }
    }
}

// MARK: - VaultStoreReorderable

extension PersistedLocalVaultStore: VaultStoreReorderable {
    public func reorder(
        items: Set<Identifier<VaultItem>>,
        to position: VaultReorderingPosition
    ) async throws {
        do {
            var allItemsDescriptor = FetchDescriptor<PersistedVaultItem>(
                predicate: .true,
                // The same order that users see so the ordering is correct.
                sortBy: sortOrder.vaultItemSortDescriptors
            )
            allItemsDescriptor.propertiesToFetch = [\.id, \.relativeOrder]
            var allItems = try modelContext.fetch(allItemsDescriptor)
            let originIndexes = items.compactMap { item in allItems.firstIndex(where: { $0.id == item.rawValue }) }
            let indexToMoveTo: Int = try {
                switch position {
                case .start:
                    return 0
                case let .after(id):
                    guard let index = allItems.firstIndex(where: { $0.id == id.rawValue }) else {
                        throw Error.relativeItemNotFound
                    }
                    return index + 1
                }
            }()
            allItems.move(fromOffsets: IndexSet(originIndexes), toOffset: indexToMoveTo)

            // Reorder all the items in their new current order.
            for (index, item) in allItems.enumerated() {
                item.relativeOrder = UInt64(index)
            }

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
            let encoder = PersistedVaultTagEncoder()
            let newTag = encoder.encode(tag: item)
            modelContext.insert(newTag)

            try modelContext.save()
            return Identifier<VaultItemTag>(id: newTag.id)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func updateTag(id: Identifier<VaultItemTag>, item: VaultItemTag.Write) async throws {
        do {
            let existing = try fetchVaultItemTag(id: id)
            let encoder = PersistedVaultTagEncoder()
            let item = encoder.encode(tag: item, existing: existing)
            modelContext.insert(item)

            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func deleteTag(id: Identifier<VaultItemTag>) async throws {
        do {
            // Delete the tag.
            let uuid = id.id
            try modelContext.delete(model: PersistedVaultTag.self, where: #Predicate {
                $0.id == uuid
            })

            // Then, remove the tag from all items that contain it.
            let tagsPredicate = makeTagsPredicate(matchingTags: [id])
            let fetchDescriptor = FetchDescriptor(predicate: tagsPredicate)
            let allItems: [PersistedVaultItem] = try modelContext.fetch(fetchDescriptor)
            for item in allItems {
                item.tags.removeAll(where: { $0.id == id.id })
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}

// MARK: - VaultStoreImporter

extension PersistedLocalVaultStore: VaultStoreImporter {
    public func importAndMergeVault(payload: VaultApplicationPayload) async throws {
        do {
            let exported = try await exportVault(userDescription: "")
            let itemUpdatedDates = exported.items
                .reduce(into: [Identifier<VaultItem>: Date]()) { partialResult, nextItem in
                    partialResult[nextItem.id] = nextItem.metadata.updated
                }
            let itemsToImport = payload.items.filter {
                // Only import item if it was updated more recently.
                $0.metadata.updated > itemUpdatedDates[$0.id, default: .distantPast]
            }

            let tagEncoder = PersistedVaultTagEncoder()
            for tag in payload.tags {
                let encoded = tagEncoder.encode(tag: tag.makeWritable(), writeUpdateContext: tag.makeImportingContext())
                modelContext.insert(encoded)
            }

            let itemEncoder = PersistedVaultItemEncoder(context: modelContext)
            for item in itemsToImport {
                let encoded = try itemEncoder.encode(
                    item: item.makeWritable(),
                    writeUpdateContext: item.makeImportingContext()
                )
                modelContext.insert(encoded)
            }

            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func importAndOverrideVault(payload: VaultApplicationPayload) async throws {
        do {
            try await deleteVault()
            let tagEncoder = PersistedVaultTagEncoder()
            for tag in payload.tags {
                let encoded = tagEncoder.encode(tag: tag.makeWritable(), writeUpdateContext: tag.makeImportingContext())
                modelContext.insert(encoded)
            }
            let itemEncoder = PersistedVaultItemEncoder(context: modelContext)
            for item in payload.items {
                let encoded = try itemEncoder.encode(
                    item: item.makeWritable(),
                    writeUpdateContext: item.makeImportingContext()
                )
                modelContext.insert(encoded)
            }

            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}

// MARK: - VaultStoreDeleter

extension PersistedLocalVaultStore: VaultStoreDeleter {
    public func deleteVault() async throws {
        do {
            for model in PersistedSchemaLatestVersion.models {
                try modelContext.delete(model: model)
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}

// MARK: - Helpers

extension PersistedLocalVaultStore {
    private func fetchVaultItem(id: Identifier<VaultItem>) throws -> PersistedVaultItem {
        let uuid = id.rawValue
        var descriptor = FetchDescriptor<PersistedVaultItem>(predicate: #Predicate { item in
            item.id == uuid
        })
        descriptor.fetchLimit = 1
        guard let existing = try modelContext.fetch(descriptor).first else {
            throw Error.modelNotFound
        }
        return existing
    }

    private func fetchVaultItemTag(id: Identifier<VaultItemTag>) throws -> PersistedVaultTag {
        let uuid = id.id
        var descriptor = FetchDescriptor<PersistedVaultTag>(predicate: #Predicate { item in
            item.id == uuid
        })
        descriptor.fetchLimit = 1
        guard let existing = try modelContext.fetch(descriptor).first else {
            throw Error.modelNotFound
        }
        return existing
    }

    private func fetchHasModelsInStorage<T: PersistentModel>(model _: T.Type) throws -> Bool {
        var itemDescriptor = FetchDescriptor<T>(predicate: .true)
        itemDescriptor.fetchLimit = 1
        let result = try modelContext.fetch(itemDescriptor)
        return result.isNotEmpty
    }
}

// MARK: - Helpers

extension VaultStoreSortOrder {
    fileprivate var vaultItemSortDescriptors: [SortDescriptor<PersistedVaultItem>] {
        switch self {
        case .relativeOrder:
            [
                // The priority is to sort by relative order.
                // This is because this is due to the user's explicit ordering.
                SortDescriptor(\.relativeOrder),
                // If two items have the same relative order, we sort by created date.
                // It's reversed so that newer items appear first.
                SortDescriptor(\.createdDate, order: .reverse),
            ]
        case .createdDate:
            [
                SortDescriptor(\.createdDate),
            ]
        }
    }
}
