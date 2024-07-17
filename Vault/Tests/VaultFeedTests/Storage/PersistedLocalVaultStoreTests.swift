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
        let code = uniqueVaultItem().asWritable
        try await sut.insert(item: code)

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.item.otpCode), [code.item.otpCode])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveAll_deliversMultipleCodesOnNonEmptyStore() async throws {
        let codes: [VaultItem.Write] = [
            uniqueVaultItem().asWritable,
            uniqueVaultItem().asWritable,
            uniqueVaultItem().asWritable,
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
            uniqueVaultItem().asWritable,
            uniqueVaultItem().asWritable,
            uniqueVaultItem().asWritable,
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
            uniqueVaultItem(visibility: .onlySearch).asWritable,
            uniqueVaultItem(visibility: .onlySearch).asWritable,
            uniqueVaultItem(visibility: .onlySearch).asWritable,
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
            uniqueVaultItem(visibility: .always).asWritable,
            uniqueVaultItem(visibility: .onlySearch).asWritable,
            uniqueVaultItem(visibility: .always).asWritable,
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.errors, [])
    }

    @MainActor
    func test_retrieveAll_returnsCorruptedItemsAsErrors() async throws {
        let codes: [VaultItem.Write] = [
            uniqueVaultItem().asWritable,
            uniqueVaultItem().asWritable,
            uniqueVaultItem().asWritable,
        ]
        var ids = [UUID]()
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
            uniqueVaultItem().asWritable,
            uniqueVaultItem().asWritable,
            uniqueVaultItem().asWritable,
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
            anySecureNote().wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem().asWritable,
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
            anySecureNote().wrapInAnyVaultItem(userDescription: "yes").asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem().asWritable,
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
            anySecureNote().wrapInAnyVaultItem(userDescription: "yes").asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem(userDescription: "no").asWritable,
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
            anySecureNote().wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem().asWritable,
            uniqueVaultItem(userDescription: "no").asWritable,
            uniqueVaultItem(userDescription: "yes").asWritable,
            uniqueVaultItem(userDescription: "no").asWritable,
            uniqueVaultItem(userDescription: "yess").asWritable,
            uniqueVaultItem(userDescription: "yesss").asWritable,
            uniqueVaultItem(userDescription: "no").asWritable,
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
            anyOTPAuthCode().wrapInAnyVaultItem().asWritable,
            uniqueVaultItem().asWritable,
            uniqueVaultItem(userDescription: "x").asWritable,
            uniqueVaultItem(userDescription: "a").asWritable,
            uniqueVaultItem(userDescription: "c").asWritable,
            uniqueVaultItem(userDescription: "b").asWritable,
            uniqueVaultItem(userDescription: "----a----").asWritable,
            uniqueVaultItem(userDescription: "----A----").asWritable,
            uniqueVaultItem(userDescription: "x").asWritable,
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
            anySecureNote().wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode(accountName: "a").wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode(accountName: "x").wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode(accountName: "----A----").wrapInAnyVaultItem().asWritable,
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
            anySecureNote().wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode(issuerName: "a").wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode(issuerName: "x").wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode(issuerName: "----A----").wrapInAnyVaultItem().asWritable,
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
            anySecureNote().wrapInAnyVaultItem().asWritable,
            anySecureNote(title: "a").wrapInAnyVaultItem().asWritable,
            anySecureNote(title: "x").wrapInAnyVaultItem().asWritable,
            anySecureNote(title: "----A----").wrapInAnyVaultItem().asWritable,
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
            anySecureNote().wrapInAnyVaultItem().asWritable,
            anySecureNote(contents: "a").wrapInAnyVaultItem().asWritable,
            anySecureNote(contents: "x").wrapInAnyVaultItem().asWritable,
            anySecureNote(contents: "----A----").wrapInAnyVaultItem().asWritable,
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
        let tag1 = try await sut.insertTag(item: anyVaultItemTag().asWritable)

        let codes: [VaultItem.Write] = [
            anySecureNote().wrapInAnyVaultItem(tags: [tag1]).asWritable,
            anySecureNote(contents: "a").wrapInAnyVaultItem(tags: [tag1]).asWritable,
            anySecureNote(contents: "x").wrapInAnyVaultItem(tags: [tag1]).asWritable,
            anySecureNote(contents: "----A----").wrapInAnyVaultItem(tags: []).asWritable, // not tagged, so not returned
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
            anySecureNote().wrapInAnyVaultItem(userDescription: "a").asWritable,
            anySecureNote(title: "aa").wrapInAnyVaultItem().asWritable,
            anySecureNote(contents: "aaa").wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem(userDescription: "aaaa").asWritable,
            anyOTPAuthCode(accountName: "aaaaa").wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode(issuerName: "aaaaaa").wrapInAnyVaultItem().asWritable,
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
            anySecureNote().wrapInAnyVaultItem(userDescription: "a", visibility: .onlySearch).asWritable,
            anySecureNote(title: "aa").wrapInAnyVaultItem(visibility: .always).asWritable,
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(visibility: .onlySearch).asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem(userDescription: "aaaa", visibility: .onlySearch).asWritable,
            anyOTPAuthCode(accountName: "aaaaa").wrapInAnyVaultItem(visibility: .onlySearch).asWritable,
            anyOTPAuthCode(issuerName: "aaaaaa").wrapInAnyVaultItem(visibility: .onlySearch).asWritable,
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
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyTitle).asWritable,
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyPassphrase).asWritable,
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(searchableLevel: .none).asWritable,
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
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyTitle).asWritable,
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyPassphrase).asWritable,
            anySecureNote(contents: "aaa").wrapInAnyVaultItem(searchableLevel: .full).asWritable,
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.count, 1, "Only 1 note matches will full search")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsItemsSearchingByTitle() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote(title: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyTitle).asWritable,
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyTitle).asWritable,
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
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyTitle).asWritable,
            anyOTPAuthCode(issuerName: "aaabbb").wrapInAnyVaultItem(searchableLevel: .onlyTitle).asWritable,
        ]
        var insertedIDs = [UUID]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let query = VaultStoreQuery(searchText: "a")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[0], insertedIDs[1]], "Matches both")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_requiresExactPassphraseMatch() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote(title: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "n")
                .asWritable,
            anyOTPAuthCode(accountName: "aaa")
                .wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "nn").asWritable,
            anyOTPAuthCode(issuerName: "aaa")
                .wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "nnn").asWritable,
        ]
        var insertedIDs = [UUID]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let query = VaultStoreQuery(searchText: "n")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[0]], "Only the first item is an exact match")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsPassphraseMatches() async throws {
        let codes: [VaultItem.Write] = [
            anySecureNote(title: "aaa").wrapInAnyVaultItem(searchableLevel: .full).asWritable,
            anySecureNote(title: "aaa").wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "a")
                .asWritable,
            anyOTPAuthCode(accountName: "aaa")
                .wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "b").asWritable,
            anyOTPAuthCode(accountName: "aaa")
                .wrapInAnyVaultItem(searchableLevel: .onlyPassphrase, searchPassphrase: "q").asWritable,
        ]
        var insertedIDs = [UUID]()
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
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode(accountName: "bbb").wrapInAnyVaultItem().asWritable, // not included
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem().asWritable,
        ]
        var ids = [UUID]()
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
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem().asWritable,
            anyOTPAuthCode(accountName: "bbb").wrapInAnyVaultItem().asWritable, // not included
            anyOTPAuthCode(accountName: "aaa").wrapInAnyVaultItem().asWritable,
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
        let tag1 = try await sut.insertTag(item: anyVaultItemTag().asWritable)

        let codes: [VaultItem.Write] = [
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).asWritable,
        ]
        var insertedIDs = [UUID]()
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
        let tag1 = try await sut.insertTag(item: anyVaultItemTag().asWritable)

        let codes: [VaultItem.Write] = [
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).asWritable,
        ]
        var insertedIDs = [UUID]()
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
        let tag1 = try await sut.insertTag(item: anyVaultItemTag().asWritable)
        let tag2 = try await sut.insertTag(item: anyVaultItemTag().asWritable)

        let codes: [VaultItem.Write] = [
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag2]).asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag2]).asWritable,
        ]
        var insertedIDs = [UUID]()
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
        let tag1 = try await sut.insertTag(item: anyVaultItemTag().asWritable)
        let tag2 = try await sut.insertTag(item: anyVaultItemTag().asWritable)
        let codes: [VaultItem.Write] = [
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1, tag2]).asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag2]).asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1, tag2]).asWritable,
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag2]).asWritable,
        ]
        var insertedIDs = [UUID]()
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
        try await sut.insert(item: uniqueVaultItem().asWritable)
    }

    func test_insert_deliversNoErrorOnNonEmptyStore() async throws {
        try await sut.insert(item: uniqueVaultItem().asWritable)
        try await sut.insert(item: uniqueVaultItem().asWritable)
    }

    func test_insert_doesNotOverrideExactSameEntryAsUsesNewIDToUnique() async throws {
        let code = uniqueVaultItem().asWritable

        try await sut.insert(item: code)
        try await sut.insert(item: code)

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.item.otpCode), [code.item.otpCode, code.item.otpCode])
        XCTAssertEqual(result.errors, [])
    }

    func test_insert_returnsUniqueCodeIDAfterSuccessfulInsert() async throws {
        let code = uniqueVaultItem().asWritable

        var ids = [UUID]()
        for _ in 0 ..< 5 {
            let id = try await sut.insert(item: code)
            ids.append(id)
        }

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.id), ids)
        XCTAssertEqual(result.errors, [])
    }

    func test_deleteByID_hasNoEffectOnEmptyStore() async throws {
        try await sut.delete(id: UUID())

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_deleteByID_deletesSingleEntryMatchingID() async throws {
        let code = uniqueVaultItem().asWritable

        let id = try await sut.insert(item: code)

        try await sut.delete(id: id)

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_deleteByID_hasNoEffectOnNoMatchingCode() async throws {
        let otherCodes = [uniqueVaultItem().asWritable, uniqueVaultItem().asWritable, uniqueVaultItem().asWritable]
        for code in otherCodes {
            try await sut.insert(item: code)
        }

        try await sut.delete(id: UUID())

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.item.otpCode), otherCodes.map(\.item.otpCode))
        XCTAssertEqual(result.errors, [])
    }

    func test_updateByID_deliversErrorIfCodeDoesNotAlreadyExist() async throws {
        do {
            try await sut.update(id: UUID(), item: uniqueVaultItem().asWritable)
            XCTFail("Expected to throw error")
        } catch {
            // ignore
        }
    }

    func test_updateByID_hasNoEffectOnEmptyStorageIfCodeDoesNotAlreadyExist() async throws {
        try? await sut.update(id: UUID(), item: uniqueVaultItem().asWritable)

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_updateByID_hasNoEffectOnNonEmptyStorageIfCodeDoesNotAlreadyExist() async throws {
        let codes = [uniqueVaultItem().asWritable, uniqueVaultItem().asWritable, uniqueVaultItem().asWritable]
        for code in codes {
            try await sut.insert(item: code)
        }

        try? await sut.update(id: UUID(), item: uniqueVaultItem().asWritable)

        let result = try await sut.retrieve(query: .all)
        XCTAssertEqual(result.items.map(\.item.otpCode), codes.map(\.item.otpCode))
        XCTAssertEqual(result.errors, [])
    }

    func test_updateByID_updatesDataForValidCode() async throws {
        let initialCode = uniqueVaultItem().asWritable
        let id = try await sut.insert(item: initialCode)

        let newCode = uniqueVaultItem().asWritable
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
        let initialCodes = [uniqueVaultItem().asWritable, uniqueVaultItem().asWritable, uniqueVaultItem().asWritable]
        for code in initialCodes {
            try await sut.insert(item: code)
        }

        let id = try await sut.insert(item: uniqueVaultItem().asWritable)

        let newCode = uniqueVaultItem().asWritable
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
        let initialCodes = [uniqueVaultItem().asWritable, uniqueVaultItem().asWritable, uniqueVaultItem().asWritable]
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
        try await sut.insertTag(item: anyVaultItemTag().asWritable)
    }

    func test_insertTag_deliversNoErrorOnNonEmptyStore() async throws {
        try await sut.insertTag(item: anyVaultItemTag().asWritable)
        try await sut.insertTag(item: anyVaultItemTag().asWritable)
    }

    func test_insertTag_doesNotOverrideExactSameEntryAsUsesNewIDToUnique() async throws {
        let code = anyVaultItemTag().asWritable

        try await sut.insertTag(item: code)
        try await sut.insertTag(item: code)

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result.count, 2)
    }

    func test_insertTag_returnsUniqueCodeIDAfterSuccessfulInsert() async throws {
        let code = anyVaultItemTag().asWritable

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
        let code = anyVaultItemTag().asWritable

        let id = try await sut.insertTag(item: code)

        try await sut.deleteTag(id: id)

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result, [])
    }

    func test_deleteTag_hasNoEffectOnNoMatchingTag() async throws {
        let otherTags = [anyVaultItemTag().asWritable, anyVaultItemTag().asWritable, anyVaultItemTag().asWritable]
        var insertedIds = [VaultItemTag.Identifier]()
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
            try await sut.updateTag(id: .init(id: UUID()), item: anyVaultItemTag().asWritable)
            XCTFail("Expected to throw error")
        } catch {
            // ignore
        }
    }

    func test_updateTag_hasNoEffectOnEmptyStorageIfDoesNotAlreadyExist() async throws {
        try? await sut.updateTag(id: .init(id: UUID()), item: anyVaultItemTag().asWritable)

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result, [])
    }

    func test_updateTag_hasNoEffectOnNonEmptyStorageIfDoesNotAlreadyExist() async throws {
        let tags = [anyVaultItemTag().asWritable, anyVaultItemTag().asWritable, anyVaultItemTag().asWritable]
        for tag in tags {
            try await sut.insertTag(item: tag)
        }

        try? await sut.updateTag(id: .init(id: UUID()), item: anyVaultItemTag().asWritable)

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result.map(\.asWritable), tags)
    }

    func test_updateTag_updatesDataForValidTag() async throws {
        let initial = anyVaultItemTag().asWritable
        let id = try await sut.insertTag(item: initial)

        let newTag = anyVaultItemTag(name: "this is the new name").asWritable
        try await sut.updateTag(id: id, item: newTag)

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result.map(\.name), ["this is the new name"])
    }

    func test_updateTag_hasNoSideEffectsOnOtherTags() async throws {
        let initialTags = [anyVaultItemTag().asWritable, anyVaultItemTag().asWritable, anyVaultItemTag().asWritable]
        var insertedIds = [VaultItemTag.Identifier]()
        for tag in initialTags {
            let id = try await sut.insertTag(item: tag)
            insertedIds.append(id)
        }

        let id = try await sut.insertTag(item: anyVaultItemTag().asWritable)

        let newTag = anyVaultItemTag().asWritable
        try await sut.updateTag(id: id, item: newTag)

        let result = try await sut.retrieveTags()
        XCTAssertEqual(result.map(\.id), insertedIds + [id])
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
