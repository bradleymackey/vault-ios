import Foundation
import FoundationExtensions
import TestHelpers
import VaultKeygen
import XCTest
@testable import VaultFeed

final class VaultDataModelTests: XCTestCase {
    @MainActor
    func test_init_hasNoStoreSideEffects() {
        let vaultStore = VaultStoreStub()
        let vaultTagStore = VaultTagStoreStub()
        _ = makeSUT(vaultStore: vaultStore, vaultTagStore: vaultTagStore)

        XCTAssertEqual(vaultStore.calledMethods, [])
        XCTAssertEqual(vaultTagStore.calledMethods, [])
    }

    @MainActor
    func test_init_initiallyFetchesBackupState() {
        let logger = BackupEventLoggerMock()
        logger.lastBackupEventHandler = { .init(
            backupDate: Date(),
            eventDate: Date(),
            kind: .exportedToPDF,
            payloadHash: .init(value: Data())
        ) }
        let sut = makeSUT(backupEventLogger: logger)

        XCTAssertEqual(logger.lastBackupEventCallCount, 1)
        XCTAssertNotNil(sut.lastBackupEvent)
    }

    @MainActor
    func test_init_initiallyFetchesBackupStateNil() {
        let logger = BackupEventLoggerMock()
        logger.lastBackupEventHandler = { nil }
        let sut = makeSUT(backupEventLogger: logger)

        XCTAssertEqual(logger.lastBackupEventCallCount, 1)
        XCTAssertNil(sut.lastBackupEvent)
    }

    @MainActor
    func test_init_monitorsChangesToBackupEventLogger() {
        let logger = BackupEventLoggerMock()
        logger.lastBackupEventHandler = { nil }
        let sut = makeSUT(backupEventLogger: logger)

        XCTAssertNil(sut.lastBackupEvent)

        let event = VaultBackupEvent(
            backupDate: Date(),
            eventDate: Date(),
            kind: .exportedToPDF,
            payloadHash: .init(value: Data())
        )
        logger.loggedEventPublisherSubject.send(event)

        XCTAssertEqual(sut.lastBackupEvent, event)

        let event2 = VaultBackupEvent(
            backupDate: Date(),
            eventDate: Date(),
            kind: .exportedToPDF,
            payloadHash: .init(value: .random(count: 32))
        )
        logger.loggedEventPublisherSubject.send(event2)

        XCTAssertEqual(sut.lastBackupEvent, event2)
    }

    @MainActor
    func test_init_initiallyEmptyData() {
        let sut = makeSUT()

        XCTAssertEqual(sut.items, [])
        XCTAssertEqual(sut.itemErrors, [])
        XCTAssertEqual(sut.itemsState, .base)
        XCTAssertNil(sut.itemsRetrievalError)
        XCTAssertEqual(sut.allTags, [])
        XCTAssertEqual(sut.allTagsState, .base)
        XCTAssertEqual(sut.backupPassword, .notFetched)
        XCTAssertNil(sut.allTagsRetrievalError)
        XCTAssertFalse(sut.hasAnyItems)
    }

    @MainActor
    func test_init_initiallyNotQueryingItems() {
        let sut = makeSUT()

        XCTAssertEqual(sut.itemsSearchQuery, "")
        XCTAssertEqual(sut.itemsFilteringByTags, [])
    }

    @MainActor
    func test_init_initialPayloadHashIsNil() {
        let store = VaultStoreStub()
        let sut = makeSUT(vaultStore: store)

        XCTAssertNil(sut.currentPayloadHash)
    }

    @MainActor
    func test_setup_computesCurrentPayloadHash() async {
        let store = VaultStoreStub()
        let sut = makeSUT(vaultStore: store)

        await sut.setup()

        XCTAssertEqual(store.calledMethods, [.export])
        XCTAssertNotNil(sut.currentPayloadHash)
    }

    @MainActor
    func test_isSearching_whenQueryingItems() {
        let sut = makeSUT()
        sut.itemsSearchQuery = " \tSOME QUERY 123\n "

        XCTAssertTrue(sut.isSearching)
    }

    @MainActor
    func test_isSearching_whenNotQueryingItems() {
        let sut = makeSUT()
        sut.itemsSearchQuery = ""
        // filtering tags does not count as searching
        sut.itemsFilteringByTags = [.init(id: UUID())]

        XCTAssertFalse(sut.isSearching)
    }

    @MainActor
    func test_toggleFiltering_addsTagToFiltering() {
        let sut = makeSUT()
        let tagID = Identifier<VaultItemTag>.new()

        sut.toggleFiltering(tag: tagID)

        XCTAssertEqual(sut.itemsFilteringByTags, [tagID])
    }

    @MainActor
    func test_toggleFiltering_removesTagFromFiltering() {
        let sut = makeSUT()
        let tagID = Identifier<VaultItemTag>.new()
        sut.itemsFilteringByTags = [tagID]

        sut.toggleFiltering(tag: tagID)

        XCTAssertEqual(sut.itemsFilteringByTags, [])
    }

    @MainActor
    func test_reloadItems_populatesNoItemsFromEmptyStore() async {
        let sut = makeSUT(vaultStore: VaultStoreStub.empty)

        await sut.reloadItems()

        XCTAssertEqual(sut.items, [])
    }

    @MainActor
    func test_reloadItems_populatesItemsFromStore() async {
        let store = VaultStoreStub()
        let sut = makeSUT(vaultStore: store)

        let exp = expectation(description: "Wait for reload data")
        store.retrieveHandler = { _ in
            defer { exp.fulfill() }
            return .init(items: [uniqueVaultItem(), uniqueVaultItem()])
        }

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.items.count, 2)
    }

    @MainActor
    func test_reloadItems_populatesItemsFromStoreQueryingText() async {
        let store = VaultStoreStub()
        let sut = makeSUT(vaultStore: store)
        sut.itemsSearchQuery = " \tSOME QUERY 123\n "

        let exp = expectation(description: "Wait for reload data")
        store.retrieveHandler = { query in
            defer { exp.fulfill() }
            XCTAssertEqual(query.filterText, "SOME QUERY 123")
            XCTAssertEqual(query.filterTags, [])
            return .init(items: [uniqueVaultItem(), uniqueVaultItem()])
        }

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.items.count, 2)
    }

    @MainActor
    func test_reloadItems_loadsItemsQueryingTextAndFiltering() async {
        let store = VaultStoreStub()
        let sut = makeSUT(vaultStore: store)
        sut.itemsSearchQuery = " \tSOME QUERY 123\n "
        let filterTags: Set<Identifier<VaultItemTag>> = [.init(id: UUID())]
        sut.itemsFilteringByTags = filterTags

        let exp = expectation(description: "Wait for reload data")
        store.retrieveHandler = { query in
            defer { exp.fulfill() }
            XCTAssertEqual(query.filterText, "SOME QUERY 123")
            XCTAssertEqual(query.filterTags, filterTags)
            return .init(items: [uniqueVaultItem(), uniqueVaultItem()])
        }

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.items.count, 2)
    }

    @MainActor
    func test_reloadItems_presentsErrorOnFailure() async {
        let store = VaultStoreErroring(error: anyNSError())
        let sut = makeSUT(vaultStore: store)

        await sut.reloadData()

        XCTAssertNotNil(sut.itemsRetrievalError)
    }

    @MainActor
    func test_reloadItems_clearsExistingError() async {
        let store = VaultStoreStub()
        store.retrieveHandler = { _ in
            throw TestError()
        }
        let sut = makeSUT(vaultStore: store)

        await sut.reloadData()

        store.retrieveHandler = { _ in .empty() }

        await sut.reloadData()

        XCTAssertNil(sut.itemsRetrievalError)
    }

    @MainActor
    func test_reloadItems_loadsHasItems() async {
        let store = VaultStoreStub()
        let sut = makeSUT(vaultStore: store)
        for hasItems in [true, false] {
            store.hasAnyItemsHandler = { hasItems }

            await sut.reloadItems()

            XCTAssertEqual(sut.hasAnyItems, hasItems)
        }
    }

    @MainActor
    func test_insert_createsItemInStoreAndReloads() async throws {
        let store = VaultStoreStub()
        let sut = makeSUT(vaultStore: store)
        let item = uniqueVaultItem().makeWritable()

        try await sut.insert(item: item)

        XCTAssertEqual(store.calledMethods, [.insert, .retrieve])
    }

    @MainActor
    func test_update_updatesItemInvalidatesAndReloads() async throws {
        let store = VaultStoreStub()
        let cache1 = VaultItemCacheMock()
        let cache2 = VaultItemCacheMock()
        let sut = makeSUT(vaultStore: store, itemCaches: [cache1, cache2])
        let item = uniqueVaultItem().makeWritable()

        try await sut.update(itemID: .new(), data: item)

        XCTAssertEqual(store.calledMethods, [.update, .retrieve, .export])
        XCTAssertEqual(cache1.invalidateVaultItemDetailCacheCallCount, 1)
        XCTAssertEqual(cache2.invalidateVaultItemDetailCacheCallCount, 1)
    }

    @MainActor
    func test_delete_deletesItemInvalidatesAndReloads() async throws {
        let store = VaultStoreStub()
        let cache1 = VaultItemCacheMock()
        let cache2 = VaultItemCacheMock()
        let sut = makeSUT(vaultStore: store, itemCaches: [cache1, cache2])

        try await sut.delete(itemID: .new())

        XCTAssertEqual(store.calledMethods, [.delete, .retrieve, .export])
        XCTAssertEqual(cache1.invalidateVaultItemDetailCacheCallCount, 1)
        XCTAssertEqual(cache2.invalidateVaultItemDetailCacheCallCount, 1)
    }

    @MainActor
    func test_reorder_reordersItemsInStore() async throws {
        let store = VaultStoreStub()
        let sut = makeSUT(vaultStore: store)
        let items = [uniqueVaultItem(), uniqueVaultItem()].map(\.id)

        try await sut.reorder(items: Set(items), to: .start)

        XCTAssertEqual(store.calledMethods, [.reorder, .export])
    }

    @MainActor
    func test_insertTag_createsTagInStoreAndReloads() async throws {
        let store = VaultTagStoreStub()
        let sut = makeSUT(vaultTagStore: store)
        let tag = anyVaultItemTag().makeWritable()

        try await sut.insert(tag: tag)

        XCTAssertEqual(store.calledMethods, [.insertTag, .retrieveTags])
    }

    @MainActor
    func test_updateTag_updatesTagInStoreAndReloads() async throws {
        let store = VaultTagStoreStub()
        let sut = makeSUT(vaultTagStore: store)
        let tag = anyVaultItemTag().makeWritable()

        try await sut.update(tagID: .new(), data: tag)

        XCTAssertEqual(store.calledMethods, [.updateTag, .retrieveTags])
    }

    @MainActor
    func test_deleteTag_deletesTagInStoreAndReloads() async throws {
        let tagStore = VaultTagStoreStub()
        let sut = makeSUT(vaultTagStore: tagStore)

        try await sut.delete(tagID: .new())

        XCTAssertEqual(tagStore.calledMethods, [.deleteTag, .retrieveTags])
    }

    @MainActor
    func test_deleteTag_removesFromCurrentFilteringAndReloads() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let sut = makeSUT(vaultStore: store, vaultTagStore: tagStore)
        let tagID = Identifier<VaultItemTag>.new()
        sut.itemsFilteringByTags = [tagID]

        try await sut.delete(tagID: tagID)

        XCTAssertEqual(store.calledMethods, [.retrieve, .export])
        XCTAssertEqual(sut.itemsFilteringByTags, [])
    }

    @MainActor
    func test_makeExport_exportsFromVaultStore() async throws {
        let store = VaultStoreStub()
        let tagStore = VaultTagStoreStub()
        let sut = makeSUT(vaultStore: store, vaultTagStore: tagStore)

        let payload = VaultApplicationPayload(userDescription: "any", items: [], tags: [])
        store.exportVaultHandler = { _ in payload }
        let exported = try await sut.makeExport(userDescription: "desc")

        XCTAssertEqual(exported, payload)
        XCTAssertEqual(store.calledMethods, [.export])
        XCTAssertEqual(tagStore.calledMethods, [])
    }

    @MainActor
    func test_loadBackupPassword_setsFetchedFromStore() async throws {
        let store = BackupPasswordStoreMock()
        let password = DerivedEncryptionKey(key: .zero(), salt: Data(), keyDervier: .testing)
        store.fetchPasswordHandler = { password }
        let sut = makeSUT(backupPasswordStore: store)

        await sut.loadBackupPassword()

        XCTAssertEqual(sut.backupPassword, .fetched(password))
        XCTAssertEqual(store.fetchPasswordCallCount, 1)
    }

    @MainActor
    func test_loadBackupPassword_setsNotCreatedIfNotInStore() async throws {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = { nil }
        let sut = makeSUT(backupPasswordStore: store)

        await sut.loadBackupPassword()

        XCTAssertEqual(sut.backupPassword, .notCreated)
        XCTAssertEqual(store.fetchPasswordCallCount, 1)
    }

    @MainActor
    func test_loadBackupPassword_setsErrorIfStoreError() async throws {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = { throw TestError() }
        let sut = makeSUT(backupPasswordStore: store)

        await sut.loadBackupPassword()

        XCTAssertTrue(sut.backupPassword.isError)
        XCTAssertEqual(store.fetchPasswordCallCount, 1)
    }

    @MainActor
    func test_storeBackupPassword_setsInStoreAndUpdatesEntry() async throws {
        let store = BackupPasswordStoreMock()
        store.setHandler = { _ in }
        let sut = makeSUT(backupPasswordStore: store)

        let password = DerivedEncryptionKey(key: .random(), salt: Data(), keyDervier: .testing)
        try await sut.store(backupPassword: password)

        XCTAssertEqual(sut.backupPassword, .fetched(password))
        XCTAssertEqual(store.setCallCount, 1)
    }

    @MainActor
    func test_storeBackupPassword_errorDoesNotUpdateEntry() async throws {
        let store = BackupPasswordStoreMock()
        store.setHandler = { _ in throw TestError() }
        let sut = makeSUT(backupPasswordStore: store)

        let password = DerivedEncryptionKey(key: .random(), salt: Data(), keyDervier: .testing)
        await XCTAssertThrowsError(try await sut.store(backupPassword: password))

        XCTAssertEqual(sut.backupPassword, .notFetched) // still initial value
        XCTAssertEqual(store.setCallCount, 1)
    }

    @MainActor
    func test_backupPassword_errorState() async {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = { throw TestError() }
        let sut = makeSUT(backupPasswordStore: store)

        await sut.loadBackupPassword()

        XCTAssertTrue(sut.backupPassword.isRetryable)
    }

    @MainActor
    func test_backupPassword_notFetched() async {
        let store = BackupPasswordStoreMock()
        let sut = makeSUT(backupPasswordStore: store)

        XCTAssertTrue(sut.backupPassword.isRetryable)
    }

    @MainActor
    func test_backupPassword_fetched() async {
        let store = BackupPasswordStoreMock()
        let password = DerivedEncryptionKey(key: .zero(), salt: Data(), keyDervier: .testing)
        store.fetchPasswordHandler = { password }
        let sut = makeSUT(backupPasswordStore: store)

        await sut.loadBackupPassword()

        XCTAssertFalse(sut.backupPassword.isRetryable)
    }

    @MainActor
    func test_backupPassword_notCreated() async {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = { nil }
        let sut = makeSUT(backupPasswordStore: store)

        await sut.loadBackupPassword()

        XCTAssertFalse(sut.backupPassword.isRetryable)
    }

    @MainActor
    func test_purgeSensitiveData_clearsBackupPassword() async {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = { DerivedEncryptionKey(key: .random(), salt: Data(), keyDervier: .testing) }
        let sut = makeSUT(backupPasswordStore: store)

        await sut.loadBackupPassword()
        sut.purgeSensitiveData()

        XCTAssertEqual(sut.backupPassword, .notFetched)
    }

    @MainActor
    func test_deleteVault_removesAllDataFromVault() async throws {
        let deleter = VaultStoreDeleterMock()
        let sut = makeSUT(vaultDeleter: deleter)

        let exp = expectation(description: "Wait for deletion")
        deleter.deleteVaultHandler = {
            exp.fulfill()
        }

        try await sut.deleteVault()

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_deleteVault_reloadsData() async throws {
        let vaultStore = VaultStoreStub()
        let vaultTagStore = VaultTagStoreStub()
        let sut = makeSUT(vaultStore: vaultStore, vaultTagStore: vaultTagStore)

        try await sut.deleteVault()

        XCTAssertEqual(vaultStore.calledMethods, [.retrieve])
        XCTAssertEqual(vaultTagStore.calledMethods, [.retrieveTags])
    }

    @MainActor
    func test_importMerge_mergesDataFromImporter() async throws {
        let importer = VaultStoreImporterMock()
        let sut = makeSUT(vaultImporter: importer)

        let exp = expectation(description: "Wait for import")
        importer.importAndMergeVaultHandler = { _ in
            exp.fulfill()
        }

        try await sut.importMerge(payload: anyApplicationPayload())

        await fulfillment(of: [exp])

        XCTAssertEqual(importer.importAndMergeVaultCallCount, 1)
        XCTAssertEqual(importer.importAndOverrideVaultCallCount, 0)
    }

    @MainActor
    func test_importMerge_reloadsStores() async throws {
        let vaultStore = VaultStoreStub()
        let vaultTagStore = VaultTagStoreStub()
        let sut = makeSUT(vaultStore: vaultStore, vaultTagStore: vaultTagStore)

        try await sut.importMerge(payload: anyApplicationPayload())

        XCTAssertEqual(vaultStore.calledMethods, [.retrieve, .export])
        XCTAssertEqual(vaultTagStore.calledMethods, [.retrieveTags])
    }

    @MainActor
    func test_importOverride_mergesDataFromImporter() async throws {
        let importer = VaultStoreImporterMock()
        let sut = makeSUT(vaultImporter: importer)

        let exp = expectation(description: "Wait for import")
        importer.importAndOverrideVaultHandler = { _ in
            exp.fulfill()
        }

        try await sut.importOverride(payload: anyApplicationPayload())

        await fulfillment(of: [exp])

        XCTAssertEqual(importer.importAndMergeVaultCallCount, 0)
        XCTAssertEqual(importer.importAndOverrideVaultCallCount, 1)
    }

    @MainActor
    func test_importOverride_reloadsStores() async throws {
        let vaultStore = VaultStoreStub()
        let vaultTagStore = VaultTagStoreStub()
        let sut = makeSUT(vaultStore: vaultStore, vaultTagStore: vaultTagStore)

        try await sut.importOverride(payload: anyApplicationPayload())

        XCTAssertEqual(vaultStore.calledMethods, [.retrieve, .export])
        XCTAssertEqual(vaultTagStore.calledMethods, [.retrieveTags])
    }
}

// MARK: - Helpers

extension VaultDataModelTests {
    @MainActor
    private func makeSUT(
        vaultStore: any VaultStore = VaultStoreStub(),
        vaultTagStore: any VaultTagStore = VaultTagStoreStub(),
        vaultImporter: any VaultStoreImporter = VaultStoreImporterMock(),
        vaultDeleter: any VaultStoreDeleter = VaultStoreDeleterMock(),
        backupPasswordStore: any BackupPasswordStore = BackupPasswordStoreMock(),
        backupEventLogger: any BackupEventLogger = BackupEventLoggerMock(),
        itemCaches: [any VaultItemCache] = []
    ) -> VaultDataModel {
        VaultDataModel(
            vaultStore: vaultStore,
            vaultTagStore: vaultTagStore,
            vaultImporter: vaultImporter,
            vaultDeleter: vaultDeleter,
            backupPasswordStore: backupPasswordStore,
            backupEventLogger: backupEventLogger,
            itemCaches: itemCaches
        )
    }

    private func anyApplicationPayload() -> VaultApplicationPayload {
        VaultApplicationPayload(userDescription: "any", items: [], tags: [])
    }
}
