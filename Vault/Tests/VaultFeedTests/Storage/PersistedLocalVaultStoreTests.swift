import Foundation
import FoundationExtensions
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

    func test_retrieveAll_deliversEmptyOnEmptyStore() async throws {
        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result, .empty())
    }

    func test_retrieveAll_hasNoSideEffectsOnEmptyStore() async throws {
        let result1 = try await sut.retrieve(query: .all)
        XCTAssertEqual(result1, .empty())
        let result2 = try await sut.retrieve(query: .all)
        XCTAssertEqual(result2, .empty())
    }

    func test_retrieveAll_deliversSingleCodeOnNonEmptyStore() async throws {
        let code = uniqueVaultItem().makeWritable()
        try await sut.insert(item: code)

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.item.otpCode), [code.item.otpCode])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveAll_deliversMultipleCodesOnNonEmptyStore() async throws {
        let codes: [VaultItem.Write] = [
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.item.otpCode), codes.map(\.item.otpCode))
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveAll_hasNoSideEffectsOnNonEmptyStore() async throws {
        let codes: [VaultItem.Write] = [
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result1 = try await sut.retrieve(query: .all)
        XCTAssertEqual(result1.items.map(\.item.otpCode), codes.map(\.item.otpCode))
        XCTAssertEqual(result1.errors, [])
        let result2 = try await sut.retrieve(query: .all)
        XCTAssertEqual(result2.items.map(\.item.otpCode), codes.map(\.item.otpCode))
        XCTAssertEqual(result2.errors, [])
    }

    func test_retrieveAll_doesNotReturnSearchOnlyItems() async throws {
        let codes: [VaultItem.Write] = [
            uniqueVaultItem(visibility: .onlySearch).makeWritable(),
            uniqueVaultItem(visibility: .onlySearch).makeWritable(),
            uniqueVaultItem(visibility: .onlySearch).makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(query: .all)
        XCTAssertTrue(result.items.isEmpty)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func test_retrieveAll_returnsAlwaysVisibleItems() async throws {
        let codes: [VaultItem.Write] = [
            uniqueVaultItem(visibility: .always).makeWritable(),
            uniqueVaultItem(visibility: .onlySearch).makeWritable(),
            uniqueVaultItem(visibility: .always).makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveAll_returnsItemsInRelativeOrder() async throws {
        let codes: [VaultItem.Write] = [
            uniqueVaultItem(relativeOrder: 3).makeWritable(),
            uniqueVaultItem(relativeOrder: 3).makeWritable(),
            uniqueVaultItem(relativeOrder: 1).makeWritable(),
            uniqueVaultItem(relativeOrder: 2).makeWritable(),
            uniqueVaultItem(relativeOrder: .min).makeWritable(),
            uniqueVaultItem(relativeOrder: 99).makeWritable(),
        ]
        var ids = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            ids.append(id)
        }

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.id), [
            ids[4], // min (default position)
            ids[2], // 1
            ids[3], // 2
            ids[0], // 3, added first
            ids[1], // 3, added second
            ids[5], // 99
        ])
        XCTAssertEqual(result.errors, [])
    }

    @MainActor
    func test_retrieveAll_returnsCorruptedItemsAsErrors() async throws {
        let codes: [VaultItem.Write] = [
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
        ]
        var ids = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            ids.append(id)
        }

        // Introduce a corruption error on the first item
        try await sut.corruptItemAlgorithm(id: ids[0])

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.id), Array(ids[1...]))
        XCTAssertEqual(result.errors, [.failedToDecode(.invalidAlgorithm)])
    }

    @MainActor
    func test_retrieveAll_returnsAllItemsCorrupted() async throws {
        let codes: [VaultItem.Write] = [
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
        ]
        for code in codes {
            let id = try await sut.insert(item: code)
            // Corrupt all items
            try await sut.corruptItemAlgorithm(id: id)
        }

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [
            .failedToDecode(.invalidAlgorithm),
            .failedToDecode(.invalidAlgorithm),
            .failedToDecode(.invalidAlgorithm),
        ])
    }

    func test_retrieveMatchingQuery_returnsEmptyOnEmptyStoreAndEmptyQuery() async throws {
        let query = VaultStoreQuery(searchText: "")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsEmptyOnEmptyStore() async throws {
        let query = VaultStoreQuery(searchText: "any")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_hasNoSideEffectsOnEmptyStore() async throws {
        let query = VaultStoreQuery(searchText: "any")
        let result1 = try await sut.retrieve(query: query)
        XCTAssertEqual(result1.items, [])
        XCTAssertEqual(result1.errors, [])
        let result2 = try await sut.retrieve(query: query)
        XCTAssertEqual(result2.items, [])
        XCTAssertEqual(result2.errors, [])
    }

    func test_retrieveMatchingQuery_returnsEmptyForNoQueryMatches() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote().wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem().makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "any")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_deliversSingleMatchOnMatchingQuery() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote().wrapInAnyVaultItem(userDescription: "yes").makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem().makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "yes")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(result.items.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_hasNoSideEffectsOnSingleMatch() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote().wrapInAnyVaultItem(userDescription: "yes").makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(userDescription: "no").makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query1 = VaultStoreQuery(searchText: "yes")
        let result1 = try await sut.retrieve(query: query1)
        XCTAssertEqual(result1.items.count, 1)
        XCTAssertEqual(result1.items.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
        XCTAssertEqual(result1.errors, [])
        let query2 = VaultStoreQuery(searchText: "yes")
        let result2 = try await sut.retrieve(query: query2)
        XCTAssertEqual(result2.items.count, 1)
        XCTAssertEqual(result2.items.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
        XCTAssertEqual(result2.errors, [])
    }

    func test_retrieveMatchingQuery_deliversMultipleMatchesOnMatchingQuery() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote().wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem().makeWritable(),
            uniqueVaultItem(userDescription: "no").makeWritable(),
            uniqueVaultItem(userDescription: "yes").makeWritable(),
            uniqueVaultItem(userDescription: "no").makeWritable(),
            uniqueVaultItem(userDescription: "yess").makeWritable(),
            uniqueVaultItem(userDescription: "yesss").makeWritable(),
            uniqueVaultItem(userDescription: "no").makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "yes")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 3)
        XCTAssertEqual(result.items.map(\.metadata.userDescription), ["yes", "yess", "yesss"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_matchesUserDescription() async throws {
        let codes: [VaultItem.Write] = [
            anyOTPAuthCode().wrapInAnyVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem(userDescription: "x").makeWritable(),
            uniqueVaultItem(userDescription: "a").makeWritable(),
            uniqueVaultItem(userDescription: "c").makeWritable(),
            uniqueVaultItem(userDescription: "b").makeWritable(),
            uniqueVaultItem(userDescription: "----a----").makeWritable(),
            uniqueVaultItem(userDescription: "----A----").makeWritable(),
            uniqueVaultItem(userDescription: "x").makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 3)
        XCTAssertEqual(result.items.map(\.metadata.userDescription), ["a", "----a----", "----A----"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_matchesOTPAccountName() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote().wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode(accountName: "a").wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode(accountName: "x").wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode(accountName: "----A----").wrapInAnyVaultItem().makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items.compactMap(\.item.otpCode?.data.accountName), ["a", "----A----"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_matchesOTPIssuer() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote().wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode(issuerName: "a").wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode(issuerName: "x").wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode(issuerName: "----A----").wrapInAnyVaultItem().makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items.compactMap(\.item.otpCode?.data.issuer), ["a", "----A----"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_matchesNoteDetailsTitle() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote().wrapInAnyVaultItem().makeWritable(),
            anySecureNote(title: "a").wrapInAnyVaultItem().makeWritable(),
            anySecureNote(title: "x").wrapInAnyVaultItem().makeWritable(),
            anySecureNote(title: "----A----").wrapInAnyVaultItem().makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items.compactMap(\.item.secureNote?.title), ["a", "----A----"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_matchesNoteDetailsContents() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote().wrapInAnyVaultItem().makeWritable(),
            anySecureNote(contents: "a").wrapInAnyVaultItem().makeWritable(),
            anySecureNote(contents: "x").wrapInAnyVaultItem().makeWritable(),
            anySecureNote(contents: "----A----").wrapInAnyVaultItem().makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items.compactMap(\.item.secureNote?.contents), ["a", "----A----"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_filtersByTagsAsWell() async throws {
        let tag1 = try await sut.insertTag(item: anyVaultItemTag().makeWritable())

        let codes: [VaultItem.Write] = [
            anySecureNote().wrapInAnyVaultItem(tags: [tag1]).makeWritable(),
            anySecureNote(contents: "a").wrapInAnyVaultItem(tags: [tag1]).makeWritable(),
            anySecureNote(contents: "x").wrapInAnyVaultItem(tags: [tag1]).makeWritable(),
            anySecureNote(contents: "----A----").wrapInAnyVaultItem(tags: []).makeWritable(),
            // not tagged, so not returned
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a", tags: [tag1])
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(result.items.compactMap(\.item.secureNote?.contents), ["a"])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_combinesResultsFromDifferentFields() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote().wrapInAnyVaultItem(userDescription: "a").makeWritable(),
            anySecureNote(title: "aa").wrapInAnyVaultItem().makeWritable(),
            anySecureNote(contents: "aaa").wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(userDescription: "aaaa").makeWritable(),
            anyOTPAuthCode(accountName: "aaaaa").wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode(issuerName: "aaaaaa").wrapInAnyVaultItem().makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 6, "All items should be matched on the specified fields")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsMatchesForAllQueryStates() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote().wrapInAnyVaultItem(userDescription: "a", visibility: .onlySearch).makeWritable(),
            anySecureNote(title: "aa").wrapInAnyVaultItem(visibility: .always).makeWritable(),
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(visibility: .onlySearch).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(userDescription: "aaaa", visibility: .onlySearch).makeWritable(),
            anyOTPAuthCode(accountName: "aaaaa").wrapInAnyVaultItem(visibility: .onlySearch).makeWritable(),
            anyOTPAuthCode(issuerName: "aaaaaa").wrapInAnyVaultItem(visibility: .onlySearch).makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 6, "All items should be matched on the specified fields")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_doesNotReturnNotesSearchingByContent() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyTitle).makeWritable(),
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyPassphrase).makeWritable(),
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(searchableLevel: .none).makeWritable(),
        ]

        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 0, "Cannot search note content in this state")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsNoteContentsIfEnabled() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyTitle).makeWritable(),
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyPassphrase).makeWritable(),
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(searchableLevel: .full).makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 1, "Only 1 note matches will full search")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_doesNotSearchContentsIfLocked() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(lockState: .notLocked).makeWritable(),
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(lockState: .lockedWithNativeSecurity).makeWritable(),
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(lockState: .lockedWithNativeSecurity).makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 1, "Only 1 note matches due to 2 items locked")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_doesSearchTitleIfLocked() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote(title: "aaa").wrapInAnyVaultItem(lockState: .notLocked).makeWritable(),
            anySecureNote(title: "aaa").wrapInAnyVaultItem(lockState: .lockedWithNativeSecurity).makeWritable(),
            anySecureNote(title: "aaa").wrapInAnyVaultItem(lockState: .lockedWithNativeSecurity).makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 3, "All 3 items returned, regardless of lock state")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsItemsSearchingByTitle() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote(title: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyTitle).makeWritable(),
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyTitle).makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 2, "All items here should be matched")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_titleOnlyMatchesOTPFields() async throws {
        let codes: [VaultItem.Write] = [
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyTitle).makeWritable(),
            anyOTPAuthCode(issuerName: "aaabbb").wrapInAnyVaultItem(searchableLevel: .onlyTitle).makeWritable(),
        ]
        var insertedIDs = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[0], insertedIDs[1]], "Matches both")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_requiresExactPassphraseMatchCaseInsensitive() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote(title: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "n")
                .makeWritable(),
            anySecureNote(title: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "N")
                .makeWritable(),
            anyOTPAuthCode(accountName: "aaa")
                .wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "nn").makeWritable(),
            anyOTPAuthCode(issuerName: "aaa")
                .wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "nnn").makeWritable(),
        ]
        var insertedIDs = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let query = VaultStoreQuery(searchText: "n")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(
            result.items.map(\.metadata.id),
            [insertedIDs[0], insertedIDs[1]],
            "Only the first item is an exact match"
        )
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsPassphraseMatches() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote(title: "aaa").wrapInAnyVaultItem(searchableLevel: .full).makeWritable(),
            anySecureNote(title: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "a")
                .makeWritable(),
            anyOTPAuthCode(accountName: "aaa")
                .wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "b").makeWritable(),
            anyOTPAuthCode(accountName: "aaa")
                .wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "q").makeWritable(),
        ]
        var insertedIDs = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
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
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode(accountName: "bbb").wrapInAnyVaultItem().makeWritable(), // not included
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem().makeWritable(),
        ]
        var ids = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            ids.append(id)
        }

        // Introduce a corruption error on the first item
        try await sut.corruptItemAlgorithm(id: ids[0])

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.map(\.id), [ids[1], ids[3]])
        XCTAssertEqual(result.errors, [.failedToDecode(.invalidAlgorithm)])
    }

    @MainActor
    func test_retrieveMatchingQuery_returnsAllItemsCorrupted() async throws {
        let codes: [VaultItem.Write] = [
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem().makeWritable(),
            anyOTPAuthCode(accountName: "bbb").wrapInAnyVaultItem().makeWritable(), // not included
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem().makeWritable(),
        ]
        for code in codes {
            let id = try await sut.insert(item: code)
            // Corrupt all items
            try await sut.corruptItemAlgorithm(id: id)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [
            .failedToDecode(.invalidAlgorithm),
            .failedToDecode(.invalidAlgorithm),
            .failedToDecode(.invalidAlgorithm),
        ])
    }

    func test_retrieveMatchingTags_returnsMatchingAllItemsIfTagNotSpecified() async throws {
        let tag1 = try await sut.insertTag(item: anyVaultItemTag().makeWritable())

        let codes: [VaultItem.Write] = [
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).makeWritable(),
        ]
        var insertedIDs = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let query = VaultStoreQuery()
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[0], insertedIDs[1]], "Returns both")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingTags_returnsMatchingAllTags() async throws {
        let tag1 = try await sut.insertTag(item: anyVaultItemTag().makeWritable())

        let codes: [VaultItem.Write] = [
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).makeWritable(),
        ]
        var insertedIDs = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let query = VaultStoreQuery(tags: [tag1])
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[0], insertedIDs[1]], "Matches both")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingTags_returnsLimitedItemsMatchingTags() async throws {
        let tag1 = try await sut.insertTag(item: anyVaultItemTag().makeWritable())
        let tag2 = try await sut.insertTag(item: anyVaultItemTag().makeWritable())

        let codes: [VaultItem.Write] = [
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag2]).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag2]).makeWritable(),
        ]
        var insertedIDs = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let query = VaultStoreQuery(tags: [tag1])
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[0], insertedIDs[2]], "Matches both")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingTags_returnsLimitedItemsMatchingTagsMultiple() async throws {
        let tag1 = try await sut.insertTag(item: anyVaultItemTag().makeWritable())
        let tag2 = try await sut.insertTag(item: anyVaultItemTag().makeWritable())
        let codes: [VaultItem.Write] = [
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1, tag2]).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag2]).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1, tag2]).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag2]).makeWritable(),
        ]
        var insertedIDs = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let query = VaultStoreQuery(tags: [tag1])
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[0], insertedIDs[2]], "Matches both")
        XCTAssertEqual(result.errors, [])
    }

    func test_insert_deliversNoErrorOnEmptyStore() async throws {
        try await sut.insert(item: uniqueVaultItem().makeWritable())
    }

    func test_insert_deliversNoErrorOnNonEmptyStore() async throws {
        try await sut.insert(item: uniqueVaultItem().makeWritable())
        try await sut.insert(item: uniqueVaultItem().makeWritable())
    }

    func test_insert_doesNotOverrideExactSameEntryAsUsesNewIDToUnique() async throws {
        let code = uniqueVaultItem().makeWritable()

        try await sut.insert(item: code)
        try await sut.insert(item: code)

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.item.otpCode), [code.item.otpCode, code.item.otpCode])
        XCTAssertEqual(result.errors, [])
    }

    func test_insert_returnsUniqueCodeIDAfterSuccessfulInsert() async throws {
        let code = uniqueVaultItem().makeWritable()

        var ids = [Identifier<VaultItem>]()
        for _ in 0 ..< 5 {
            let id = try await sut.insert(item: code)
            ids.append(id)
        }

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.id), ids)
        XCTAssertEqual(result.errors, [])
    }

    func test_deleteByID_hasNoEffectOnEmptyStore() async throws {
        try await sut.delete(id: .new())

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_deleteByID_deletesSingleEntryMatchingID() async throws {
        let code = uniqueVaultItem().makeWritable()

        let id = try await sut.insert(item: code)

        try await sut.delete(id: id)

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_deleteByID_hasNoEffectOnNoMatchingCode() async throws {
        let otherCodes = [
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
        ]
        for code in otherCodes {
            try await sut.insert(item: code)
        }

        try await sut.delete(id: Identifier<VaultItem>())

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.item.otpCode), otherCodes.map(\.item.otpCode))
        XCTAssertEqual(result.errors, [])
    }

    func test_updateByID_deliversErrorIfCodeDoesNotAlreadyExist() async throws {
        do {
            try await sut.update(id: Identifier<VaultItem>(), item: uniqueVaultItem().makeWritable())
            XCTFail("Expected to throw error")
        } catch {
            // ignore
        }
    }

    func test_updateByID_hasNoEffectOnEmptyStorageIfCodeDoesNotAlreadyExist() async throws {
        try? await sut.update(id: Identifier<VaultItem>(), item: uniqueVaultItem().makeWritable())

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_updateByID_hasNoEffectOnNonEmptyStorageIfCodeDoesNotAlreadyExist() async throws {
        let codes = [
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        try? await sut.update(id: Identifier<VaultItem>(), item: uniqueVaultItem().makeWritable())

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.item.otpCode), codes.map(\.item.otpCode))
        XCTAssertEqual(result.errors, [])
    }

    func test_updateByID_updatesDataForValidCode() async throws {
        let initialCode = uniqueVaultItem().makeWritable()
        let id = try await sut.insert(item: initialCode)

        let newCode = uniqueVaultItem().makeWritable()
        try await sut.update(id: id, item: newCode)

        let result = try await sut.retrieve(query: .all)
        XCTAssertNotEqual(
            result.items.map(\.item.otpCode),
            [initialCode.item.otpCode],
            "Should be different from old code."
        )
        XCTAssertEqual(result.items.map(\.item.otpCode), [newCode.item.otpCode], "Should be the same as the new code.")
        XCTAssertEqual(result.errors, [])
    }

    func test_updateByID_hasNoSideEffectsOnOtherCodes() async throws {
        let initialCodes = [
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
        ]
        for code in initialCodes {
            try await sut.insert(item: code)
        }

        let id = try await sut.insert(item: uniqueVaultItem().makeWritable())

        let newCode = uniqueVaultItem().makeWritable()
        try await sut.update(id: id, item: newCode)

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.item.otpCode), initialCodes.map(\.item.otpCode) + [newCode.item.otpCode])
        XCTAssertEqual(result.errors, [])
    }

    func test_exportVault_hasNoSideEffectsOnEmptyVault() async throws {
        _ = try await sut.exportVault(userDescription: "")

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result, .empty())
    }

    func test_exportVault_hasNoSideEffectsOnNonEmptyVault() async throws {
        let initialCodes = [
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
        ]
        for code in initialCodes {
            try await sut.insert(item: code)
        }

        _ = try await sut.exportVault(userDescription: "my desc")

        let result = try await sut.retrieve(query: .all)
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
        var insertedIDs = [Identifier<VaultItem>]()
        for code in items {
            let id = try await sut.insert(item: code.makeWritable())
            insertedIDs.append(id)
        }

        let export = try await sut.exportVault(userDescription: "my description")

        XCTAssertEqual(export.userDescription, "my description")
        XCTAssertEqual(export.items.map { $0.makeWritable() }, items.map { $0.makeWritable() })
        XCTAssertEqual(export.items.map(\.id), insertedIDs)
        XCTAssertEqual(export.tags, [])
    }

    func test_retrieveTags_returnsNoTagsIfThereAreNone() async throws {
        let tags = try await sut.retrieveTags()

        XCTAssertEqual(tags, [])
    }

    func test_retrieveTags_returnsMultipleTags() async throws {
        let items = [
            VaultItemTag.Write(name: "any1", color: nil, iconName: nil),
            VaultItemTag.Write(name: "any2", color: nil, iconName: nil),
            VaultItemTag.Write(name: "any3", color: nil, iconName: nil),
        ]
        var insertedIDs = [UUID]()
        for tag in items {
            let id = try await sut.insertTag(item: tag)
            insertedIDs.append(id.id)
        }
        let tags = try await sut.retrieveTags()

        XCTAssertEqual(tags.map(\.id.id), insertedIDs)
    }

    func test_insertTag_deliversNoErrorOnEmptyStore() async throws {
        try await sut.insertTag(item: anyVaultItemTag().makeWritable())
    }

    func test_insertTag_deliversNoErrorOnNonEmptyStore() async throws {
        try await sut.insertTag(item: anyVaultItemTag().makeWritable())
        try await sut.insertTag(item: anyVaultItemTag().makeWritable())
    }

    func test_insertTag_doesNotOverrideExactSameEntryAsUsesNewIDToUnique() async throws {
        let code = anyVaultItemTag().makeWritable()

        try await sut.insertTag(item: code)
        try await sut.insertTag(item: code)

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result.count, 2)
    }

    func test_insertTag_returnsUniqueCodeIDAfterSuccessfulInsert() async throws {
        let code = anyVaultItemTag().makeWritable()

        var ids = [UUID]()
        for _ in 0 ..< 5 {
            let id = try await sut.insertTag(item: code)
            ids.append(id.id)
        }

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result.map(\.id.id), ids)
    }

    func test_deleteTag_hasNoEffectOnEmptyStore() async throws {
        try await sut.deleteTag(id: .init(id: UUID()))

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result, [])
    }

    func test_deleteTag_deletesSingleEntryMatchingID() async throws {
        let code = anyVaultItemTag().makeWritable()

        let id = try await sut.insertTag(item: code)

        try await sut.deleteTag(id: id)

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result, [])
    }

    func test_deleteTag_hasNoEffectOnNoMatchingTag() async throws {
        let otherTags = [
            anyVaultItemTag().makeWritable(),
            anyVaultItemTag().makeWritable(),
            anyVaultItemTag().makeWritable(),
        ]
        var insertedIds = [Identifier<VaultItemTag>]()
        for tag in otherTags {
            let id = try await sut.insertTag(item: tag)
            insertedIds.append(id)
        }

        try await sut.deleteTag(id: .init(id: UUID()))

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result.map(\.id), insertedIds)
    }

    func test_updateTag_deliversErrorIfCodeDoesNotAlreadyExist() async throws {
        do {
            try await sut.updateTag(id: .init(id: UUID()), item: anyVaultItemTag().makeWritable())
            XCTFail("Expected to throw error")
        } catch {
            // ignore
        }
    }

    func test_updateTag_hasNoEffectOnEmptyStorageIfDoesNotAlreadyExist() async throws {
        try? await sut.updateTag(id: .init(id: UUID()), item: anyVaultItemTag().makeWritable())

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result, [])
    }

    func test_updateTag_hasNoEffectOnNonEmptyStorageIfDoesNotAlreadyExist() async throws {
        let tags = [
            anyVaultItemTag().makeWritable(),
            anyVaultItemTag().makeWritable(),
            anyVaultItemTag().makeWritable(),
        ]
        for tag in tags {
            try await sut.insertTag(item: tag)
        }

        try? await sut.updateTag(id: .init(id: UUID()), item: anyVaultItemTag().makeWritable())

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result.map { $0.makeWritable() }, tags)
    }

    func test_updateTag_updatesDataForValidTag() async throws {
        let initial = anyVaultItemTag().makeWritable()
        let id = try await sut.insertTag(item: initial)

        let newTag = anyVaultItemTag(name: "this is the new name").makeWritable()
        try await sut.updateTag(id: id, item: newTag)

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result.map(\.name), ["this is the new name"])
    }

    func test_updateTag_hasNoSideEffectsOnOtherTags() async throws {
        let initialTags = [
            anyVaultItemTag().makeWritable(),
            anyVaultItemTag().makeWritable(),
            anyVaultItemTag().makeWritable(),
        ]
        var insertedIds = [Identifier<VaultItemTag>]()
        for tag in initialTags {
            let id = try await sut.insertTag(item: tag)
            insertedIds.append(id)
        }

        let id = try await sut.insertTag(item: anyVaultItemTag().makeWritable())

        let newTag = anyVaultItemTag().makeWritable()
        try await sut.updateTag(id: id, item: newTag)

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result.map(\.id), insertedIds + [id])
    }
}

// MARK: - Helpers

extension PersistedLocalVaultStore {
    fileprivate func corruptItemAlgorithm(id: Identifier<VaultItem>) async throws {
        let uuid = id.rawValue
        var descriptor = FetchDescriptor<PersistedVaultItem>(predicate: #Predicate { item in
            item.id == uuid
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
