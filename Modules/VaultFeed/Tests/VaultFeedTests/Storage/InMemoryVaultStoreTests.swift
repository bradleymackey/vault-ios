import Foundation
import TestHelpers
import VaultFeed
import XCTest

final class InMemoryVaultStoreTests: XCTestCase {
    func test_retrieve_noCodesReturnsNone() async throws {
        let sut = makeSUT(codes: [])

        let retrieved = try await sut.retrieve()
        XCTAssertEqual(retrieved, [StoredVaultItem]())
    }

    func test_retrieve_codeReturned() async throws {
        let code1 = uniqueStoredCode()
        let sut = makeSUT(codes: [code1])

        let retrieved = try await sut.retrieve()
        XCTAssertEqual(retrieved, [code1])
    }

    func test_insert_addsNewCodeToRepository() async throws {
        let sut = makeSUT(codes: [])

        let code1 = uniqueWritableCode()
        let newID = try await sut.insert(code: code1)

        let retrieved = try await sut.retrieve()
        XCTAssertEqual(retrieved.count, 1)
        let code = try XCTUnwrap(retrieved.first)
        XCTAssertEqual(code.id, newID)
        XCTAssertEqual(code.asWritable, code1)
    }

    func test_update_throwsIfCodeNotFound() async throws {
        let sut = makeSUT(codes: [])

        // swiftformat:disable:next hoistAwait
        await XCTAssertThrowsError(try await sut.update(id: UUID(), code: uniqueWritableCode()))
    }

    func test_update_updatesExistingCode() async throws {
        let code1 = uniqueStoredCode()
        let sut = makeSUT(codes: [code1])

        let newCode = uniqueCode()
        let newUserDescription = UUID().uuidString
        try await sut.update(id: code1.id, code: .init(userDescription: newUserDescription, code: newCode))

        let retrieved = try await sut.retrieve()
        XCTAssertEqual(retrieved.count, 1)
        let code = try XCTUnwrap(retrieved.first)
        XCTAssertEqual(code.id, code1.id)
        XCTAssertEqual(code.userDescription, newUserDescription)
        XCTAssertEqual(code.code, newCode)
    }

    func test_delete_ignoresIfCodeDoesNotExist() async throws {
        let sut = makeSUT(codes: [])
        try await sut.delete(id: UUID())

        let retrieved = try await sut.retrieve()
        XCTAssertEqual(retrieved, [])
    }

    func test_delete_removesCode() async throws {
        let code1 = uniqueStoredCode()
        let code2 = uniqueStoredCode()
        let sut = makeSUT(codes: [code1, code2])
        try await sut.delete(id: code1.id)

        let retrieved = try await sut.retrieve()
        XCTAssertEqual(retrieved, [code2])
    }
}

extension InMemoryVaultStoreTests {
    private func makeSUT(codes: [StoredVaultItem]) -> InMemoryVaultStore {
        InMemoryVaultStore(codes: codes)
    }
}
