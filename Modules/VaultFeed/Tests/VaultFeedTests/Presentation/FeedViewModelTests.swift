import Combine
import Foundation
import TestHelpers
import VaultFeed
import XCTest

@MainActor
final class FeedViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!
    override func setUp() {
        super.setUp()
        cancellables = Set()
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    func test_reloadData_populatesEmptyCodesFromStore() async throws {
        let sut = makeSUT(store: StubStore.empty)

        await expectSingleMutation(observable: sut, keyPath: \.codes) {
            await sut.reloadData()
        }
        XCTAssertEqual(sut.codes, [])
    }

    func test_reloadData_doesNotShowErrorOnPopulatingFromEmpty() async throws {
        let sut = makeSUT(store: StubStore.empty)

        await expectNoMutation(observable: sut, keyPath: \.retrievalError) {
            await sut.reloadData()
        }
        XCTAssertNil(sut.retrievalError)
    }

    func test_reloadData_populatesCodesFromStore() async throws {
        let store = StubStore(codes: [uniqueStoredCode(), uniqueStoredCode()])
        let sut = makeSUT(store: store)

        await expectSingleMutation(observable: sut, keyPath: \.codes) {
            await sut.reloadData()
        }
        XCTAssertEqual(sut.codes, store.codes)
    }

    func test_reloadData_doesNotShowErrorOnPopulatingFromNonEmpty() async throws {
        let store = StubStore(codes: [uniqueStoredCode(), uniqueStoredCode()])
        let sut = makeSUT(store: store)

        await expectNoMutation(observable: sut, keyPath: \.retrievalError) {
            await sut.reloadData()
        }
        XCTAssertNil(sut.retrievalError)
    }

    func test_reloadData_presentsErrorOnFeedReloadError() async throws {
        let sut = makeSUT(store: ErrorStubStore(error: anyNSError()))

        await expectSingleMutation(observable: sut, keyPath: \.retrievalError) {
            await sut.reloadData()
        }
        XCTAssertNotNil(sut.retrievalError)
    }

    func test_updateCode_updatesStore() async throws {
        var store = StubStore()
        let exp = expectation(description: "Wait for store update")
        store.updateStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.update(id: UUID(), code: uniqueWritableCode())

        await fulfillment(of: [exp])
    }

    func test_updateCode_reloadsAfterUpdate() async throws {
        var store = StubStore()
        let exp = expectation(description: "Wait for store retrieve")
        store.retrieveStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.update(id: UUID(), code: uniqueWritableCode())

        await fulfillment(of: [exp])
    }

    func test_updateCode_doesNotReloadOnFailure() async throws {
        var store = ErrorStubStore(error: anyNSError())
        let exp = expectation(description: "Wait for store not retrieve")
        exp.isInverted = true
        store.retrieveStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try? await sut.update(id: UUID(), code: uniqueWritableCode())

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_updateCode_invalidatesCaches() async throws {
        let cache1 = StubCodeCache()
        let cache2 = StubCodeCache()
        let sut = makeSUT(store: StubStore(), caches: [cache1, cache2])

        let invalidateId = UUID()
        try await sut.update(id: invalidateId, code: uniqueWritableCode())

        XCTAssertEqual(cache1.calledInvalidate, [invalidateId])
        XCTAssertEqual(cache2.calledInvalidate, [invalidateId])
    }

    func test_deleteCode_removesFromStore() async throws {
        var store = StubStore()
        let exp = expectation(description: "Wait for store delete")
        store.deleteStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.delete(id: UUID())

        await fulfillment(of: [exp])
    }

    func test_deleteCode_reloadsAfterDelete() async throws {
        var store = StubStore()
        let exp = expectation(description: "Wait for store retrieve")
        store.retrieveStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try await sut.delete(id: UUID())

        await fulfillment(of: [exp])
    }

    func test_deleteCode_doesNotReloadOnFailure() async throws {
        var store = ErrorStubStore(error: anyNSError())
        let exp = expectation(description: "Wait for store not retrieve")
        exp.isInverted = true
        store.retrieveStoreCalled = {
            exp.fulfill()
        }

        let sut = makeSUT(store: store)

        try? await sut.delete(id: UUID())

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_deleteCode_invalidatesCaches() async throws {
        let cache1 = StubCodeCache()
        let cache2 = StubCodeCache()
        let sut = makeSUT(store: StubStore(), caches: [cache1, cache2])

        let invalidateId = UUID()
        try await sut.delete(id: invalidateId)

        XCTAssertEqual(cache1.calledInvalidate, [invalidateId])
        XCTAssertEqual(cache2.calledInvalidate, [invalidateId])
    }

    // MARK: - Helpers

    private func makeSUT<T: VaultStoreReader>(
        store: T,
        caches: [any CodeDetailCache] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FeedViewModel<T> {
        let sut = FeedViewModel(store: store, caches: caches)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private final class StubCodeCache: CodeDetailCache {
        var calledInvalidate = [UUID]()
        func invalidateCodeDetailCache(forCodeWithID id: UUID) {
            calledInvalidate.append(id)
        }
    }

    private struct StubStore: VaultStoreReader, VaultStoreWriter {
        var codes = [StoredVaultItem]()
        var retrieveStoreCalled: () -> Void = {}
        func retrieve() async throws -> [StoredVaultItem] {
            retrieveStoreCalled()
            return codes
        }

        static var empty: StubStore {
            .init(codes: [])
        }

        func insert(code _: VaultFeed.StoredVaultItem.Write) async throws -> UUID {
            UUID()
        }

        var updateStoreCalled: () -> Void = {}
        func update(id _: UUID, code _: VaultFeed.StoredVaultItem.Write) async throws {
            updateStoreCalled()
        }

        var deleteStoreCalled: () -> Void = {}
        func delete(id _: UUID) async throws {
            deleteStoreCalled()
        }
    }

    private struct ErrorStubStore: VaultStoreReader, VaultStoreWriter {
        var error: Error
        var retrieveStoreCalled: () -> Void = {}
        func retrieve() async throws -> [StoredVaultItem] {
            retrieveStoreCalled()
            throw error
        }

        func insert(code _: VaultFeed.StoredVaultItem.Write) async throws -> UUID {
            throw error
        }

        func update(id _: UUID, code _: VaultFeed.StoredVaultItem.Write) async throws {
            throw error
        }

        func delete(id _: UUID) async throws {
            throw error
        }
    }
}
