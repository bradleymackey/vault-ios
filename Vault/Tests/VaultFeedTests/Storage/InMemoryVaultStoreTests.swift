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
        let code1 = uniqueStoredVaultItem()
        let sut = makeSUT(codes: [code1])

        let retrieved = try await sut.retrieve()
        XCTAssertEqual(retrieved, [code1])
    }

    func test_retrieveMatchingQuery_noCodesReturnsNone() async throws {
        let sut = makeSUT(codes: [])

        let retrieved = try await sut.retrieve(matching: "any")
        XCTAssertEqual(retrieved, [StoredVaultItem]())
    }

    func test_retrieveMatchingQuery_emptyQueryReturnsAll() async throws {
        let code1 = uniqueStoredVaultItem()
        let sut = makeSUT(codes: [code1])

        let retrieved = try await sut.retrieve(matching: "")
        XCTAssertEqual(retrieved, [code1])
    }

    func test_retrieveMatchingQuery_matchesUserDescription() async throws {
        let codes: [StoredVaultItem] = [
            searchableStoredSecureNoteVaultItem(userDescription: "a"),
            searchableStoredSecureNoteVaultItem(userDescription: "--A--"),
            searchableStoredSecureNoteVaultItem(userDescription: "x"),
            searchableStoredOTPVaultItem(userDescription: "a"),
            searchableStoredOTPVaultItem(userDescription: "--a--"),
            searchableStoredOTPVaultItem(userDescription: "x"),
        ]
        let sut = makeSUT(codes: codes)

        let retrieved = try await sut.retrieve(matching: "a")
        XCTAssertEqual(retrieved.map(\.metadata.userDescription), ["a", "--A--", "a", "--a--"])
    }

    func test_retrieveMatchingQuery_matchesOTPAccountName() async throws {
        let codes: [StoredVaultItem] = [
            searchableStoredOTPVaultItem(accountName: "a"),
            searchableStoredOTPVaultItem(accountName: "x"),
            searchableStoredOTPVaultItem(accountName: "--a--"),
            searchableStoredOTPVaultItem(accountName: "x"),
            searchableStoredOTPVaultItem(accountName: "A"),
        ]
        let sut = makeSUT(codes: codes)

        let retrieved = try await sut.retrieve(matching: "a")
        XCTAssertEqual(retrieved.map(\.item.otpCode?.data.accountName), ["a", "--a--", "A"])
    }

    func test_retrieveMatchingQuery_matchesOTPIssuerName() async throws {
        let codes: [StoredVaultItem] = [
            searchableStoredOTPVaultItem(issuerName: "a"),
            searchableStoredOTPVaultItem(issuerName: "x"),
            searchableStoredOTPVaultItem(issuerName: "--a--"),
            searchableStoredOTPVaultItem(issuerName: "x"),
            searchableStoredOTPVaultItem(issuerName: "A"),
        ]
        let sut = makeSUT(codes: codes)

        let retrieved = try await sut.retrieve(matching: "a")
        XCTAssertEqual(retrieved.map(\.item.otpCode?.data.issuer), ["a", "--a--", "A"])
    }

    func test_retrieveMatchingQuery_matchesSecureNoteTitle() async throws {
        let codes: [StoredVaultItem] = [
            searchableStoredSecureNoteVaultItem(title: "a"),
            searchableStoredSecureNoteVaultItem(title: "x"),
            searchableStoredSecureNoteVaultItem(title: "--a--"),
            searchableStoredSecureNoteVaultItem(title: "x"),
            searchableStoredSecureNoteVaultItem(title: "A"),
        ]
        let sut = makeSUT(codes: codes)

        let retrieved = try await sut.retrieve(matching: "a")
        XCTAssertEqual(retrieved.map(\.item.secureNote?.title), ["a", "--a--", "A"])
    }

    func test_retrieveMatchingQuery_matchesSecureNoteContents() async throws {
        let codes: [StoredVaultItem] = [
            searchableStoredSecureNoteVaultItem(contents: "a"),
            searchableStoredSecureNoteVaultItem(contents: "x"),
            searchableStoredSecureNoteVaultItem(contents: "--a--"),
            searchableStoredSecureNoteVaultItem(contents: "x"),
            searchableStoredSecureNoteVaultItem(contents: "A"),
        ]
        let sut = makeSUT(codes: codes)

        let retrieved = try await sut.retrieve(matching: "a")
        XCTAssertEqual(retrieved.map(\.item.secureNote?.contents), ["a", "--a--", "A"])
    }

    func test_retrieveMatchingQuery_combinesMatchesFromDifferentFields() async throws {
        let codes: [StoredVaultItem] = [
            searchableStoredSecureNoteVaultItem(title: "a"),
            searchableStoredSecureNoteVaultItem(contents: "aa"),
            searchableStoredSecureNoteVaultItem(userDescription: "aaa"),
            searchableStoredOTPVaultItem(accountName: "aaaa"),
            searchableStoredOTPVaultItem(issuerName: "aaaaa"),
            searchableStoredOTPVaultItem(userDescription: "aaaaaa"),
        ]
        let sut = makeSUT(codes: codes)

        let retrieved = try await sut.retrieve(matching: "a")
        XCTAssertEqual(retrieved, codes, "All items, matched on their own fields, should be returned")
    }

    func test_insert_addsNewCodeToRepository() async throws {
        let sut = makeSUT(codes: [])

        let code1 = uniqueWritableVaultItem()
        let newID = try await sut.insert(item: code1)

        let retrieved = try await sut.retrieve()
        XCTAssertEqual(retrieved.count, 1)
        let code = try XCTUnwrap(retrieved.first)
        XCTAssertEqual(code.id, newID)
        XCTAssertEqual(code.asWritable, code1)
    }

    func test_update_throwsIfCodeNotFound() async throws {
        let sut = makeSUT(codes: [])

        // swiftformat:disable:next hoistAwait
        await XCTAssertThrowsError(try await sut.update(id: UUID(), item: uniqueWritableVaultItem()))
    }

    func test_update_updatesExistingCode() async throws {
        let code1 = uniqueStoredVaultItem()
        let sut = makeSUT(codes: [code1])

        let newCode = uniqueCode()
        let newUserDescription = UUID().uuidString
        let newColor = VaultItemColor(red: 0.1, green: 0.1, blue: 0.1)
        try await sut.update(
            id: code1.id,
            item: .init(userDescription: newUserDescription, color: newColor, item: .otpCode(newCode))
        )

        let retrieved = try await sut.retrieve()
        XCTAssertEqual(retrieved.count, 1)
        let item = try XCTUnwrap(retrieved.first)
        XCTAssertEqual(item.id, code1.id)
        XCTAssertEqual(item.metadata.userDescription, newUserDescription)
        XCTAssertEqual(item.metadata.color, newColor)
        XCTAssertEqual(item.item, .otpCode(newCode))
    }

    func test_delete_ignoresIfCodeDoesNotExist() async throws {
        let sut = makeSUT(codes: [])
        try await sut.delete(id: UUID())

        let retrieved = try await sut.retrieve()
        XCTAssertEqual(retrieved, [])
    }

    func test_delete_removesCode() async throws {
        let code1 = uniqueStoredVaultItem()
        let code2 = uniqueStoredVaultItem()
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
