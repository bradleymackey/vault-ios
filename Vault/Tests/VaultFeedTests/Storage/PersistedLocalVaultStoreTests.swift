import Foundation
import SwiftData
import TestHelpers
import VaultCore
import XCTest
@testable import VaultFeed

final class PersistedLocalVaultStoreTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var sut: PersistedLocalVaultStore!

    override func setUp() async throws {
        try await super.setUp()

        let container = try ModelContainer(
            for: PersistedVaultItem.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        sut = PersistedLocalVaultStore(modelContainer: container)
    }

    func test_retrieve_deliversEmptyOnEmptyStore() async throws {
        let result = try await sut.retrieve()
        XCTAssertEqual(result, .empty())
    }

    func test_retrieve_hasNoSideEffectsOnEmptyStore() async throws {
        let result1 = try await sut.retrieve()
        XCTAssertEqual(result1, .empty())
        let result2 = try await sut.retrieve()
        XCTAssertEqual(result2, .empty())
    }

    func test_retrieve_deliversSingleCodeOnNonEmptyStore() async throws {
        let code = uniqueWritableVaultItem()
        try await sut.insert(item: code)

        let result = try await sut.retrieve()
        XCTAssertEqual(result.items.map(\.item.otpCode), [code.item.otpCode])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieve_deliversMultipleCodesOnNonEmptyStore() async throws {
        let codes: [VaultItem.Write] = [
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve()
        XCTAssertEqual(result.items.map(\.item.otpCode), codes.map(\.item.otpCode))
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyStore() async throws {
        let codes: [VaultItem.Write] = [
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result1 = try await sut.retrieve()
        XCTAssertEqual(result1.items.map(\.item.otpCode), codes.map(\.item.otpCode))
        XCTAssertEqual(result1.errors, [])
        let result2 = try await sut.retrieve()
        XCTAssertEqual(result2.items.map(\.item.otpCode), codes.map(\.item.otpCode))
        XCTAssertEqual(result2.errors, [])
    }

    func test_retrieve_doesNotReturnSearchOnlyItems() async throws {
        let codes: [VaultItem.Write] = [
            uniqueWritableVaultItem(visibility: .onlySearch),
            uniqueWritableVaultItem(visibility: .onlySearch),
            uniqueWritableVaultItem(visibility: .onlySearch),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve()
        XCTAssertTrue(result.items.isEmpty)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func test_retrieve_returnsAlwaysVisibleItems() async throws {
        let codes: [VaultItem.Write] = [
            uniqueWritableVaultItem(visibility: .always),
            uniqueWritableVaultItem(visibility: .onlySearch),
            uniqueWritableVaultItem(visibility: .always),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve()
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.errors, [])
    }

    @MainActor
    func test_retrieve_returnsCorruptedItemsAsErrors() async throws {
        let codes: [VaultItem.Write] = [
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
        ]
        var ids = [UUID]()
        for code in codes {
            let id = try await sut.insert(item: code)
            ids.append(id)
        }

        // Introduce a corruption error on the first item
        try await sut.corruptItemAlgorithm(id: ids[0])

        let result = try await sut.retrieve()
        XCTAssertEqual(result.items.map(\.id), Array(ids[1...]))
        XCTAssertEqual(result.errors, [.failedToDecode(.invalidAlgorithm)])
    }

    @MainActor
    func test_retrieve_returnsAllItemsCorrupted() async throws {
        let codes: [VaultItem.Write] = [
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
            uniqueWritableVaultItem(),
        ]
        for code in codes {
            let id = try await sut.insert(item: code)
            // Corrupt all items
            try await sut.corruptItemAlgorithm(id: id)
        }

        let result = try await sut.retrieve()
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [
            .failedToDecode(.invalidAlgorithm),
            .failedToDecode(.invalidAlgorithm),
            .failedToDecode(.invalidAlgorithm),
        ])
    }

    func test_retrieveMatchingQuery_returnsEmptyOnEmptyStoreAndEmptyQuery() async throws {
        let result = try await sut.retrieve(matching: "")
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsEmptyOnEmptyStore() async throws {
        let result = try await sut.retrieve(matching: "any")
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_hasNoSideEffectsOnEmptyStore() async throws {
        let result1 = try await sut.retrieve(matching: "any")
        XCTAssertEqual(result1.items, [])
        XCTAssertEqual(result1.errors, [])
        let result2 = try await sut.retrieve(matching: "any")
        XCTAssertEqual(result2.items, [])
        XCTAssertEqual(result2.errors, [])
    }

    func test_retrieveMatchingQuery_returnsEmptyForNoQueryMatches() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableOTPVaultItem(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "any")
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_deliversSingleMatchOnMatchingQuery() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(userDescription: "yes"),
            writableSearchableOTPVaultItem(userDescription: "no"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "yes")
        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(result.items.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_hasNoSideEffectsOnSingleMatch() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(userDescription: "yes"),
            writableSearchableOTPVaultItem(userDescription: "no"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result1 = try await sut.retrieve(matching: "yes")
        XCTAssertEqual(result1.items.count, 1)
        XCTAssertEqual(result1.items.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
        XCTAssertEqual(result1.errors, [])
        let result2 = try await sut.retrieve(matching: "yes")
        XCTAssertEqual(result2.items.count, 1)
        XCTAssertEqual(result2.items.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
        XCTAssertEqual(result2.errors, [])
    }

    func test_retrieveMatchingQuery_deliversMultipleMatchesOnMatchingQuery() async throws {
        let codes: [VaultItem.Write] = [
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
        XCTAssertEqual(result.items.count, 3)
        XCTAssertEqual(result.items.map(\.metadata.userDescription), ["yes", "yess", "yesss"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_matchesUserDescription() async throws {
        let codes: [VaultItem.Write] = [
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
        XCTAssertEqual(result.items.count, 3)
        XCTAssertEqual(result.items.map(\.metadata.userDescription), ["a", "----a----", "----A----"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_matchesOTPAccountName() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableOTPVaultItem(accountName: "a"),
            writableSearchableOTPVaultItem(accountName: "x"),
            writableSearchableOTPVaultItem(accountName: "----A----"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items.compactMap(\.item.otpCode?.data.accountName), ["a", "----A----"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_matchesOTPIssuer() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableOTPVaultItem(issuerName: "a"),
            writableSearchableOTPVaultItem(issuerName: "x"),
            writableSearchableOTPVaultItem(issuerName: "----A----"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items.compactMap(\.item.otpCode?.data.issuer), ["a", "----A----"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_matchesNoteDetailsTitle() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableNoteVaultItem(title: "a"),
            writableSearchableNoteVaultItem(title: "x"),
            writableSearchableNoteVaultItem(title: "----A----"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items.compactMap(\.item.secureNote?.title), ["a", "----A----"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_matchesNoteDetailsContents() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(),
            writableSearchableNoteVaultItem(contents: "a"),
            writableSearchableNoteVaultItem(contents: "x"),
            writableSearchableNoteVaultItem(contents: "----A----"),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items.compactMap(\.item.secureNote?.contents), ["a", "----A----"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_combinesResultsFromDifferentFields() async throws {
        let codes: [VaultItem.Write] = [
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
        XCTAssertEqual(result.items.count, 6, "All items should be matched on the specified fields")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsMatchesForAllQueryStates() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(userDescription: "a", visibility: .onlySearch),
            writableSearchableNoteVaultItem(title: "aa", visibility: .always),
            writableSearchableNoteVaultItem(contents: "aaa", visibility: .onlySearch),
            writableSearchableOTPVaultItem(userDescription: "aaaa", visibility: .onlySearch),
            writableSearchableOTPVaultItem(accountName: "aaaaa", visibility: .onlySearch),
            writableSearchableOTPVaultItem(issuerName: "aaaaaa", visibility: .onlySearch),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.items.count, 6, "All items should be matched on the specified fields")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_doesNotReturnNotesSearchingByContent() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(contents: "aaa", searchableLevel: .onlyTitle),
            writableSearchableNoteVaultItem(contents: "aaa", searchableLevel: .onlyPassphrase),
            writableSearchableNoteVaultItem(contents: "aaa", searchableLevel: .none),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.items.count, 0, "Cannot search note content in this state")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsNoteContentsIfEnabled() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(contents: "aaa", searchableLevel: .onlyTitle),
            writableSearchableNoteVaultItem(contents: "aaa", searchableLevel: .onlyPassphrase),
            writableSearchableNoteVaultItem(contents: "aaa", searchableLevel: .full),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.items.count, 1, "Only 1 note matches will full search")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsItemsSearchingByTitle() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(title: "aaa", searchableLevel: .onlyTitle),
            writableSearchableOTPVaultItem(accountName: "aaa", searchableLevel: .onlyTitle),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.items.count, 2, "All items here should be matched")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_titleOnlyMatchesOTPFields() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableOTPVaultItem(accountName: "aaa", searchableLevel: .onlyTitle),
            writableSearchableOTPVaultItem(issuerName: "aaabbb", searchableLevel: .onlyTitle),
        ]
        var insertedIDs = [UUID]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[0], insertedIDs[1]], "Matches both")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_requiresExactPassphraseMatch() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(title: "aaa", searchableLevel: .onlyPassphrase, searchPassphrase: "n"),
            writableSearchableOTPVaultItem(
                accountName: "aaa",
                searchableLevel: .onlyPassphrase,
                searchPassphrase: "nn"
            ),
            writableSearchableOTPVaultItem(
                accountName: "aaa",
                searchableLevel: .onlyPassphrase,
                searchPassphrase: "nnn"
            ),
        ]
        var insertedIDs = [UUID]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let result = try await sut.retrieve(matching: "n")
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[0]], "Only the first item is an exact match")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsPassphraseMatches() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableNoteVaultItem(title: "aaa", searchableLevel: .full),
            writableSearchableNoteVaultItem(title: "aaa", searchableLevel: .onlyPassphrase, searchPassphrase: "a"),
            writableSearchableOTPVaultItem(accountName: "aaa", searchableLevel: .onlyPassphrase, searchPassphrase: "b"),
            writableSearchableOTPVaultItem(accountName: "aaa", searchableLevel: .onlyPassphrase, searchPassphrase: "q"),
        ]
        var insertedIDs = [UUID]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(
            result.items.map(\.metadata.id),
            [insertedIDs[0], insertedIDs[1]],
            "Matches first on text, second on passphrase"
        )
        XCTAssertEqual(result.errors, [])
    }

    @MainActor
    func test_retrieveMatchingQuery_returnsCorruptedItemsAsErrors() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableOTPVaultItem(accountName: "aaa"),
            writableSearchableOTPVaultItem(accountName: "aaa"),
            writableSearchableOTPVaultItem(accountName: "bbb"), // not included
            writableSearchableOTPVaultItem(accountName: "aaa"),
        ]
        var ids = [UUID]()
        for code in codes {
            let id = try await sut.insert(item: code)
            ids.append(id)
        }

        // Introduce a corruption error on the first item
        try await sut.corruptItemAlgorithm(id: ids[0])

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.items.map(\.id), [ids[1], ids[3]])
        XCTAssertEqual(result.errors, [.failedToDecode(.invalidAlgorithm)])
    }

    @MainActor
    func test_retrieveMatchingQuery_returnsAllItemsCorrupted() async throws {
        let codes: [VaultItem.Write] = [
            writableSearchableOTPVaultItem(accountName: "aaa"),
            writableSearchableOTPVaultItem(accountName: "aaa"),
            writableSearchableOTPVaultItem(accountName: "bbb"), // not included
            writableSearchableOTPVaultItem(accountName: "aaa"),
        ]
        for code in codes {
            let id = try await sut.insert(item: code)
            // Corrupt all items
            try await sut.corruptItemAlgorithm(id: id)
        }

        let result = try await sut.retrieve(matching: "a")
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [
            .failedToDecode(.invalidAlgorithm),
            .failedToDecode(.invalidAlgorithm),
            .failedToDecode(.invalidAlgorithm),
        ])
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
        XCTAssertEqual(result.items.map(\.item.otpCode), [code.item.otpCode, code.item.otpCode])
        XCTAssertEqual(result.errors, [])
    }

    func test_insert_returnsUniqueCodeIDAfterSuccessfulInsert() async throws {
        let code = uniqueWritableVaultItem()

        var ids = [UUID]()
        for _ in 0 ..< 5 {
            let id = try await sut.insert(item: code)
            ids.append(id)
        }

        let result = try await sut.retrieve()
        XCTAssertEqual(result.items.map(\.id), ids)
        XCTAssertEqual(result.errors, [])
    }

    func test_deleteByID_hasNoEffectOnEmptyStore() async throws {
        try await sut.delete(id: UUID())

        let result = try await sut.retrieve()
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_deleteByID_deletesSingleEntryMatchingID() async throws {
        let code = uniqueWritableVaultItem()

        let id = try await sut.insert(item: code)

        try await sut.delete(id: id)

        let result = try await sut.retrieve()
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_deleteByID_hasNoEffectOnNoMatchingCode() async throws {
        let otherCodes = [uniqueWritableVaultItem(), uniqueWritableVaultItem(), uniqueWritableVaultItem()]
        for code in otherCodes {
            try await sut.insert(item: code)
        }

        try await sut.delete(id: UUID())

        let result = try await sut.retrieve()
        XCTAssertEqual(result.items.map(\.item.otpCode), otherCodes.map(\.item.otpCode))
        XCTAssertEqual(result.errors, [])
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
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_updateByID_hasNoEffectOnNonEmptyStorageIfCodeDoesNotAlreadyExist() async throws {
        let codes = [uniqueWritableVaultItem(), uniqueWritableVaultItem(), uniqueWritableVaultItem()]
        for code in codes {
            try await sut.insert(item: code)
        }

        try? await sut.update(id: UUID(), item: uniqueWritableVaultItem())

        let result = try await sut.retrieve()
        XCTAssertEqual(result.items.map(\.item.otpCode), codes.map(\.item.otpCode))
        XCTAssertEqual(result.errors, [])
    }

    func test_updateByID_updatesDataForValidCode() async throws {
        let initialCode = uniqueWritableVaultItem()
        let id = try await sut.insert(item: initialCode)

        let newCode = uniqueWritableVaultItem()
        try await sut.update(id: id, item: newCode)

        let result = try await sut.retrieve()
        XCTAssertNotEqual(
            result.items.map(\.item.otpCode),
            [initialCode.item.otpCode],
            "Should be different from old code."
        )
        XCTAssertEqual(result.items.map(\.item.otpCode), [newCode.item.otpCode], "Should be the same as the new code.")
        XCTAssertEqual(result.errors, [])
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
        XCTAssertEqual(result.items.map(\.item.otpCode), initialCodes.map(\.item.otpCode) + [newCode.item.otpCode])
        XCTAssertEqual(result.errors, [])
    }

    func test_exportVault_hasNoSideEffectsOnEmptyVault() async throws {
        _ = try await sut.exportVault(userDescription: "")

        let result = try await sut.retrieve()
        XCTAssertEqual(result, .empty())
    }

    func test_exportVault_hasNoSideEffectsOnNonEmptyVault() async throws {
        let initialCodes = [uniqueWritableVaultItem(), uniqueWritableVaultItem(), uniqueWritableVaultItem()]
        for code in initialCodes {
            try await sut.insert(item: code)
        }

        _ = try await sut.exportVault(userDescription: "my desc")

        let result = try await sut.retrieve()
        XCTAssertEqual(result.items.count, 3)
    }

    func test_exportVault_empty() async throws {
        let export = try await sut.exportVault(userDescription: "my description!")

        XCTAssertEqual(export.userDescription, "my description!")
        XCTAssertEqual(export.items, [])
        XCTAssertEqual(export.tags, [])
    }

    func test_exportVault_withContent() async throws {
        let items = [uniqueVaultItem(), uniqueVaultItem(), uniqueVaultItem()]
        var insertedIDs = [UUID]()
        for code in items {
            let id = try await sut.insert(item: code.asWritable)
            insertedIDs.append(id)
        }

        let export = try await sut.exportVault(userDescription: "my description")

        XCTAssertEqual(export.userDescription, "my description")
        XCTAssertEqual(export.items.map(\.asWritable), items.map(\.asWritable))
        XCTAssertEqual(export.items.map(\.id), insertedIDs)
        XCTAssertEqual(export.tags, [])
    }
}

// MARK: - Helpers

extension PersistedLocalVaultStore {
    fileprivate func corruptItemAlgorithm(id: UUID) async throws {
        var descriptor = FetchDescriptor<PersistedVaultItem>(predicate: #Predicate { item in
            item.id == id
        })
        descriptor.fetchLimit = 1
        guard let existing = try? modelContext.fetch(descriptor).first else {
            return
        }
        existing.otpDetails?.algorithm = "INVALID"

        modelContext.insert(existing)
        try modelContext.save()
    }
}
