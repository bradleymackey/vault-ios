import Foundation
import SwiftData
import TestHelpers
import VaultCore
import VaultFeed
import XCTest

final class PersistedLocalVaultStoreTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var sut: PersistedLocalVaultStore!

    override func setUp() async throws {
        try await super.setUp()

        sut = try PersistedLocalVaultStore(configuration: .inMemory)
    }

    func test_retrieve_deliversEmptyOnEmptyStore() async throws {
        let result = try await sut.retrieve()
        XCTAssertEqual(result, [])
    }

    func test_retrieve_hasNoSideEffectsOnEmptyStore() async throws {
        let result1 = try await sut.retrieve()
        XCTAssertEqual(result1, [])
        let result2 = try await sut.retrieve()
        XCTAssertEqual(result2, [])
    }

    func test_retrieve_deliversSingleCodeOnNonEmptyStore() async throws {
        let code = uniqueWritableVaultItem()
        try await sut.insert(item: code)

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.item.otpCode), [code.item.otpCode])
    }

    func test_retrieve_deliversMultipleCodesOnNonEmptyStore() async throws {
        let codes: [StoredVaultItem.Write] = [
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.item.otpCode), codes.map(\.item.otpCode))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyStore() async throws {
        let codes: [StoredVaultItem.Write] = [
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result1 = try await sut.retrieve()
        XCTAssertEqual(result1.map(\.item.otpCode), codes.map(\.item.otpCode))
        let result2 = try await sut.retrieve()
        XCTAssertEqual(result2.map(\.item.otpCode), codes.map(\.item.otpCode))
    }

    func test_retrieveMatchingQuery_returnsEmptyOnEmptyStoreAndEmptyQuery() async throws {
        let result = try await sut.retrieve(matching: "")
        XCTAssertEqual(result, [])
    }

    func test_retrieveMatchingQuery_returnsEmptyOnEmptyStore() async throws {
        let result = try await sut.retrieve(matching: "any")
        XCTAssertEqual(result, [])
    }

    func test_retrieveMatchingQuery_hasNoSideEffectsOnEmptyStore() async throws {
        let result1 = try await sut.retrieve(matching: "any")
        XCTAssertEqual(result1, [])
        let result2 = try await sut.retrieve(matching: "any")
        XCTAssertEqual(result2, [])
    }

    func test_retrieveMatchingQuery_returnsEmptyForNoQueryMatches() async throws {
        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableOTPVaultItem(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "any")
        XCTAssertEqual(result, [])
    }

    func test_retrieveMatchingQuery_deliversSingleMatchOnMatchingQuery() async throws {
        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(userDescription: "yes"),
            writableSearchableOTPVaultItem(userDescription: "no"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "yes")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
    }

    func test_retrieveMatchingQuery_hasNoSideEffectsOnSingleMatch() async throws {
        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(userDescription: "yes"),
            writableSearchableOTPVaultItem(userDescription: "no"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result1 = try await sut.retrieve(matching: "yes")
        XCTAssertEqual(result1.count, 1)
        XCTAssertEqual(result1.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
        let result2 = try await sut.retrieve(matching: "yes")
        XCTAssertEqual(result2.count, 1)
        XCTAssertEqual(result2.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
    }

    func test_retrieveMatchingQuery_deliversMultipleMatchesOnMatchingQuery() async throws {
        let codes: [StoredVaultItem.Write] = [
            writableSearchableOTPVaultItem(userDescription: "no"),
            writableSearchableNoteVaultItem(userDescription: "yes"),
            writableSearchableOTPVaultItem(userDescription: "no"),
            writableSearchableOTPVaultItem(userDescription: "yess"),
            writableSearchableOTPVaultItem(userDescription: "yesss"),
            writableSearchableOTPVaultItem(userDescription: "no"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "yes")
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.map(\.metadata.userDescription), ["yes", "yess", "yesss"])
    }

    func test_retrieveMatchingQuery_matchesUserDescription() async throws {
        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableOTPVaultItem(userDescription: "x"),
            writableSearchableNoteVaultItem(userDescription: "a"),
            writableSearchableOTPVaultItem(userDescription: "c"),
            writableSearchableOTPVaultItem(userDescription: "b"),
            writableSearchableOTPVaultItem(userDescription: "----a----"),
            writableSearchableOTPVaultItem(userDescription: "----A----"),
            writableSearchableOTPVaultItem(userDescription: "x"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.map(\.metadata.userDescription), ["a", "----a----", "----A----"])
    }

    func test_retrieveMatchingQuery_matchesOTPAccountName() async throws {
        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableOTPVaultItem(accountName: "a"),
            writableSearchableOTPVaultItem(accountName: "x"),
            writableSearchableOTPVaultItem(accountName: "----A----"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.compactMap(\.item.otpCode?.data.accountName), ["a", "----A----"])
    }

    func test_retrieveMatchingQuery_matchesOTPIssuer() async throws {
        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableOTPVaultItem(issuerName: "a"),
            writableSearchableOTPVaultItem(issuerName: "x"),
            writableSearchableOTPVaultItem(issuerName: "----A----"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.compactMap(\.item.otpCode?.data.issuer), ["a", "----A----"])
    }

    func test_retrieveMatchingQuery_matchesNoteDetailsTitle() async throws {
        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableNoteVaultItem(title: "a"),
            writableSearchableNoteVaultItem(title: "x"),
            writableSearchableNoteVaultItem(title: "----A----"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.compactMap(\.item.secureNote?.title), ["a", "----A----"])
    }

    func test_retrieveMatchingQuery_matchesNoteDetailsContents() async throws {
        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableNoteVaultItem(contents: "a"),
            writableSearchableNoteVaultItem(contents: "x"),
            writableSearchableNoteVaultItem(contents: "----A----"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.compactMap(\.item.secureNote?.contents), ["a", "----A----"])
    }

    func test_retrieveMatchingQuery_combinesResultsFromDifferentFields() async throws {
        let codes: [StoredVaultItem.Write] = [
            writableSearchableNoteVaultItem(userDescription: "a"),
            writableSearchableNoteVaultItem(title: "aa"),
            writableSearchableNoteVaultItem(contents: "aaa"),
            writableSearchableOTPVaultItem(userDescription: "aaaa"),
            writableSearchableOTPVaultItem(accountName: "aaaaa"),
            writableSearchableOTPVaultItem(issuerName: "aaaaaa"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.count, 6, "All items should be matched on the specified fields")
    }

    func test_insert_deliversNoErrorOnEmptyStore() async throws {
        try await sut.insert(item: uniqueWritableVaultItem())
    }

    func test_insert_deliversNoErrorOnNonEmptyStore() async throws {
        try await sut.insert(item: uniqueWritableVaultItem())
        try await sut.insert(item: uniqueWritableVaultItem())
    }

    func test_insert_doesNotOverrideExactSameEntryAsUsesNewIDToUnique() async throws {
        let code = uniqueWritableVaultItem()

        try await sut.insert(item: code)
        try await sut.insert(item: code)

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.item.otpCode), [code.item.otpCode, code.item.otpCode])
    }

    func test_insert_returnsUniqueCodeIDAfterSuccessfulInsert() async throws {
        let code = uniqueWritableVaultItem()

        var ids = [UUID]()
        for _ in 0 ..< 5 {
            let id = try await sut.insert(item: code)
            ids.append(id)
        }

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.id), ids)
    }

    func test_deleteByID_hasNoEffectOnEmptyStore() async throws {
        try await sut.delete(id: UUID())

        let results = try await sut.retrieve()
        XCTAssertEqual(results, [])
    }

    func test_deleteByID_deletesSingleEntryMatchingID() async throws {
        let code = uniqueWritableVaultItem()

        let id = try await sut.insert(item: code)

        try await sut.delete(id: id)

        let results = try await sut.retrieve()
        XCTAssertEqual(results, [])
    }

    func test_deleteByID_hasNoEffectOnNoMatchingCode() async throws {
        let otherCodes = [uniqueWritableVaultItem(), uniqueWritableVaultItem(), uniqueWritableVaultItem()]
        for code in otherCodes {
            try await sut.insert(item: code)
        }

        try await sut.delete(id: UUID())

        let results = try await sut.retrieve()
        XCTAssertEqual(results.map(\.item.otpCode), otherCodes.map(\.item.otpCode))
    }

    func test_updateByID_deliversErrorIfCodeDoesNotAlreadyExist() async throws {
        do {
            try await sut.update(id: UUID(), item: uniqueWritableVaultItem())
            XCTFail("Expected to throw error")
        } catch {
            // ignore
        }
    }

    func test_updateByID_hasNoEffectOnEmptyStorageIfCodeDoesNotAlreadyExist() async throws {
        try? await sut.update(id: UUID(), item: uniqueWritableVaultItem())

        let result = try await sut.retrieve()
        XCTAssertEqual(result, [])
    }

    func test_updateByID_hasNoEffectOnNonEmptyStorageIfCodeDoesNotAlreadyExist() async throws {
        let codes = [uniqueWritableVaultItem(), uniqueWritableVaultItem(), uniqueWritableVaultItem()]
        for code in codes {
            try await sut.insert(item: code)
        }

        try? await sut.update(id: UUID(), item: uniqueWritableVaultItem())

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.item.otpCode), codes.map(\.item.otpCode))
    }

    func test_updateByID_updatesDataForValidCode() async throws {
        let initialCode = uniqueWritableVaultItem()
        let id = try await sut.insert(item: initialCode)

        let newCode = uniqueWritableVaultItem()
        try await sut.update(id: id, item: newCode)

        let result = try await sut.retrieve()
        XCTAssertNotEqual(result.map(\.item.otpCode), [initialCode.item.otpCode], "Should be different from old code.")
        XCTAssertEqual(result.map(\.item.otpCode), [newCode.item.otpCode], "Should be the same as the new code.")
    }

    func test_updateByID_hasNoSideEffectsOnOtherCodes() async throws {
        let initialCodes = [uniqueWritableVaultItem(), uniqueWritableVaultItem(), uniqueWritableVaultItem()]
        for code in initialCodes {
            try await sut.insert(item: code)
        }

        let id = try await sut.insert(item: uniqueWritableVaultItem())

        let newCode = uniqueWritableVaultItem()
        try await sut.update(id: id, item: newCode)

        let result = try await sut.retrieve()
        XCTAssertEqual(result.map(\.item.otpCode), initialCodes.map(\.item.otpCode) + [newCode.item.otpCode])
    }
}
