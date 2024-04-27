import Combine
import Foundation
import TestHelpers
import VaultFeed
import XCTest

final class FeedViewModelTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set()
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    @MainActor
    func test_reloadData_populatesEmptyCodesFromStore() async throws {
        let sut = makeSUT(store: StubStore.empty)

        await expectSingleMutation(observable: sut, keyPath: \.codes) {
            await sut.reloadData()
        }
        XCTAssertEqual(sut.codes, [])
    }

    @MainActor
    func test_reloadData_doesNotShowErrorOnPopulatingFromEmpty() async throws {
        let sut = makeSUT(store: StubStore.empty)

        await expectNoMutation(observable: sut, keyPath: \.retrievalError) {
            await sut.reloadData()
        }
        XCTAssertNil(sut.retrievalError)
    }

    @MainActor
    func test_reloadData_populatesCodesFromStore() async throws {
        let store = StubStore()
        store.codes = [uniqueStoredVaultItem(), uniqueStoredVaultItem()]
        let sut = makeSUT(store: store)

        let exp = expectation(description: "Wait for reload data")
        store.retrieveStoreCalled = {
            exp.fulfill()
        }

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.codes, store.codes)
    }

    @MainActor
    func test_reloadData_populatesCodesIfQueryIsNotPresent() async throws {
        let store = StubStore()
        store.codes = [uniqueStoredVaultItem(), uniqueStoredVaultItem()]
        let sut = makeSUT(store: store)
        sut.searchQuery = "  " // whitespace only

        let exp = expectation(description: "Wait for reload data from normal store, not search")
        store.retrieveStoreCalled = {
            exp.fulfill()
        }

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.codes, store.codes)
    }

    @MainActor
    func test_reloadData_populatesCodesFromQueryIfQueryIsPresent() async throws {
        let store = StubStore()
        store.codesMatchingQuery = [uniqueStoredVaultItem(), uniqueStoredVaultItem()]
        let sut = makeSUT(store: store)
        sut.searchQuery = " \tSOME QUERY 123\n "

        let exp = expectation(description: "Wait for reload data")
        store.retrieveStoreMatchingQueryCalled = { query in
            XCTAssertEqual(query, "SOME QUERY 123")
            exp.fulfill()
        }

        await sut.reloadData()

        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.codes, store.codesMatchingQuery)
    }

    @MainActor
    func test_reloadData_doesNotShowErrorOnPopulatingFromNonEmpty() async throws {
        let store = StubStore()
        store.codes = [uniqueStoredVaultItem(), uniqueStoredVaultItem()]
        let sut = makeSUT(store: store)

        await expectNoMutation(observable: sut, keyPath: \.retrievalError) {
            await sut.reloadData()
        }
        XCTAssertNil(sut.retrievalError)
    }

    @MainActor
    func test_reloadData_presentsErrorOnFeedReloadError() async throws {
        let sut = makeSUT(store: ErrorStubStore(error: anyNSError()))

        await expectSingleMutation(observable: sut, keyPath: \.retrievalError) {
            await sut.reloadData()
        }
        XCTAssertNotNil(sut.retrievalError)
    }

    @MainActor
    func test_createItem_updatesStore() async throws {
        let store = StubStore()
        let exp = expectation(description: "Wait for store update")
        store.insertStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.create(item: uniqueWritableVaultItem())

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_createItem_reloadsAfterUpdate() async throws {
        let store = StubStore()
        let exp = expectation(description: "Wait for store update")
        store.retrieveStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.create(item: uniqueWritableVaultItem())

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_createItem_doesNotReloadOnFailure() async throws {
        let store = ErrorStubStore(error: anyNSError())
        let exp = expectation(description: "Wait for store update")
        exp.isInverted = true
        store.retrieveStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try? await sut.create(item: uniqueWritableVaultItem())

        await fulfillment(of: [exp], timeout: 1.0)
    }

    @MainActor
    func test_createItem_doesNotInvalidateAnyCaches() async throws {
        let cache1 = VaultItemCacheSpy()
        let cache2 = VaultItemCacheSpy()
        let sut = makeSUT(store: StubStore(), caches: [cache1, cache2])

        try await sut.create(item: uniqueWritableVaultItem())

        XCTAssertEqual(cache1.invalidateVaultItemDetailCacheForVaultItemWithIDReceivedInvocations, [])
        XCTAssertEqual(cache2.invalidateVaultItemDetailCacheForVaultItemWithIDReceivedInvocations, [])
    }

    @MainActor
    func test_updateCode_updatesStore() async throws {
        let store = StubStore()
        let exp = expectation(description: "Wait for store update")
        store.updateStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.update(id: UUID(), item: uniqueWritableVaultItem())

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_updateCode_reloadsAfterUpdate() async throws {
        let store = StubStore()
        let exp = expectation(description: "Wait for store retrieve")
        store.retrieveStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.update(id: UUID(), item: uniqueWritableVaultItem())

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_updateCode_doesNotReloadOnFailure() async throws {
        let store = ErrorStubStore(error: anyNSError())
        let exp = expectation(description: "Wait for store not retrieve")
        exp.isInverted = true
        store.retrieveStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try? await sut.update(id: UUID(), item: uniqueWritableVaultItem())

        await fulfillment(of: [exp], timeout: 1.0)
    }

    @MainActor
    func test_updateCode_invalidatesCaches() async throws {
        let cache1 = VaultItemCacheSpy()
        let cache2 = VaultItemCacheSpy()
        let sut = makeSUT(store: StubStore(), caches: [cache1, cache2])

        let invalidateId = UUID()
        try await sut.update(id: invalidateId, item: uniqueWritableVaultItem())

        XCTAssertEqual(cache1.invalidateVaultItemDetailCacheForVaultItemWithIDReceivedInvocations, [invalidateId])
        XCTAssertEqual(cache2.invalidateVaultItemDetailCacheForVaultItemWithIDReceivedInvocations, [invalidateId])
    }

    @MainActor
    func test_deleteCode_removesFromStore() async throws {
        let store = StubStore()
        let exp = expectation(description: "Wait for store delete")
        store.deleteStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.delete(id: UUID())

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_deleteCode_reloadsAfterDelete() async throws {
        let store = StubStore()
        let exp = expectation(description: "Wait for store retrieve")
        store.retrieveStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.delete(id: UUID())

        await fulfillment(of: [exp])
    }

    @MainActor
    func test_deleteCode_doesNotReloadOnFailure() async throws {
        let store = ErrorStubStore(error: anyNSError())
        let exp = expectation(description: "Wait for store not retrieve")
        exp.isInverted = true
        store.retrieveStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try? await sut.delete(id: UUID())

        await fulfillment(of: [exp], timeout: 1.0)
    }

    @MainActor
    func test_deleteCode_invalidatesCaches() async throws {
        let cache1 = VaultItemCacheSpy()
        let cache2 = VaultItemCacheSpy()
        let sut = makeSUT(store: StubStore(), caches: [cache1, cache2])

        let invalidateId = UUID()
        try await sut.delete(id: invalidateId)

        XCTAssertEqual(cache1.invalidateVaultItemDetailCacheForVaultItemWithIDReceivedInvocations, [invalidateId])
        XCTAssertEqual(cache2.invalidateVaultItemDetailCacheForVaultItemWithIDReceivedInvocations, [invalidateId])
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT<T: VaultStoreReader>(
        store: T,
        caches: [any VaultItemCache] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedViewModel<T> {
        let sut = FeedViewModel(store: store, caches: caches)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private final class StubStore: VaultStoreReader, VaultStoreWriter {
        var codes = [StoredVaultItem]()
        var retrieveStoreCalled: () -> Void = {}
        func retrieve() async throws -> [StoredVaultItem] {
            retrieveStoreCalled()
            return codes
        }

        var codesMatchingQuery = [StoredVaultItem]()
        var retrieveStoreMatchingQueryCalled: (String) -> Void = { _ in }
        func retrieve(matching query: String) async throws -> [StoredVaultItem] {
            retrieveStoreMatchingQueryCalled(query)
            return codesMatchingQuery
        }

        static var empty: StubStore {
            .init()
        }

        var insertStoreCalled: () -> Void = {}
        func insert(item _: StoredVaultItem.Write) async throws -> UUID {
            insertStoreCalled()
            return UUID()
        }

        var updateStoreCalled: () -> Void = {}
        func update(id _: UUID, item _: StoredVaultItem.Write) async throws {
            updateStoreCalled()
        }

        var deleteStoreCalled: () -> Void = {}
        func delete(id _: UUID) async throws {
            deleteStoreCalled()
        }
    }

    private final class ErrorStubStore: VaultStoreReader, VaultStoreWriter {
        var error: any Error
        init(error: any Error) {
            self.error = error
        }

        var retrieveStoreCalled: () -> Void = {}
        func retrieve() async throws -> [StoredVaultItem] {
            retrieveStoreCalled()
            throw error
        }

        var retrieveStoreMatchingQueryCalled: (String) -> Void = { _ in }
        func retrieve(matching query: String) async throws -> [StoredVaultItem] {
            retrieveStoreMatchingQueryCalled(query)
            throw error
        }

        func insert(item _: StoredVaultItem.Write) async throws -> UUID {
            throw error
        }

        func update(id _: UUID, item _: StoredVaultItem.Write) async throws {
            throw error
        }

        func delete(id _: UUID) async throws {
            throw error
        }
    }
}
