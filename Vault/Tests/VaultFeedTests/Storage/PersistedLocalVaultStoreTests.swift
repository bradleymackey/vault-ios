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
        await sut.updateSortOrder(.createdDate)
    }

    func test_retrieveAll_deliversEmptyOnEmptyStore() async throws {
        let result = try await sut.retrieve(query: .init())
        XCTAssertEqual(result, .empty())
    }

    func test_retrieveAll_hasNoSideEffectsOnEmptyStore() async throws {
        let result1 = try await sut.retrieve(query: .init())
        XCTAssertEqual(result1, .empty())
        let result2 = try await sut.retrieve(query: .init())
        XCTAssertEqual(result2, .empty())
    }

    func test_retrieveAll_deliversSingleCodeOnNonEmptyStore() async throws {
        let code = uniqueVaultItem().makeWritable()
        try await sut.insert(item: code)

        let result = try await sut.retrieve(query: .init())
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

        let result = try await sut.retrieve(query: .init())
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

        let result1 = try await sut.retrieve(query: .init())
        XCTAssertEqual(result1.items.map(\.item.otpCode), codes.map(\.item.otpCode))
        XCTAssertEqual(result1.errors, [])
        let result2 = try await sut.retrieve(query: .init())
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

        let result = try await sut.retrieve(query: .init())
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

        let result = try await sut.retrieve(query: .init())
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveAll_relativeOrderReturnsItemsInRelativeOrder() async throws {
        await sut.updateSortOrder(.relativeOrder)

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

        let result = try await sut.retrieve(query: .init())
        XCTAssertEqual(result.items.map(\.id), [
            ids[4], // min (default position)
            ids[2], // 1
            ids[3], // 2
            ids[1], // 3, added second (more recently)
            ids[0], // 3, added first (less recently)
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

        let result = try await sut.retrieve(query: .init())
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

        let result = try await sut.retrieve(query: .init())
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [
            .failedToDecode(.invalidAlgorithm),
            .failedToDecode(.invalidAlgorithm),
            .failedToDecode(.invalidAlgorithm),
        ])
    }

    func test_retrieveMatchingQuery_returnsEmptyOnEmptyStoreAndEmptyQuery() async throws {
        let query = VaultStoreQuery(filterText: "")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_returnsEmptyOnEmptyStore() async throws {
        let query = VaultStoreQuery(filterText: "any")
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingQuery_hasNoSideEffectsOnEmptyStore() async throws {
        let query = VaultStoreQuery(filterText: "any")
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

        let query = VaultStoreQuery(filterText: "any")
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

        let query = VaultStoreQuery(filterText: "yes")
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

        let query1 = VaultStoreQuery(filterText: "yes")
        let result1 = try await sut.retrieve(query: query1)
        XCTAssertEqual(result1.items.count, 1)
        XCTAssertEqual(result1.items.compactMap(\.item.secureNote), codes.compactMap(\.item.secureNote))
        XCTAssertEqual(result1.errors, [])
        let query2 = VaultStoreQuery(filterText: "yes")
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

        let query = VaultStoreQuery(filterText: "yes")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a", filterTags: [tag1])
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "n")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterText: "a")
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

        let query = VaultStoreQuery(filterTags: [tag1])
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[0], insertedIDs[1]], "Matches both")
        XCTAssertEqual(result.errors, [])
    }

    func test_retrieveMatchingTags_returnsMatchingTags_ANDSemantics() async throws {
        let tag1 = try await sut.insertTag(item: anyVaultItemTag().makeWritable())
        let tag2 = try await sut.insertTag(item: anyVaultItemTag().makeWritable())

        let codes: [VaultItem.Write] = [
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1]).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1, tag2]).makeWritable(),
        ]
        var insertedIDs = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            insertedIDs.append(id)
        }

        let query1 = VaultStoreQuery(filterTags: [tag1])
        let result1 = try await sut.retrieve(query: query1)
        XCTAssertEqual(result1.items.count, 2)
        XCTAssertEqual(result1.errors, [])

        let query2 = VaultStoreQuery(filterTags: [tag1, tag2])
        let result2 = try await sut.retrieve(query: query2)
        XCTAssertEqual(result2.items.map(\.metadata.id), [insertedIDs[1]], "Matches second only with AND semantics")
        XCTAssertEqual(result2.errors, [])
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

        let query = VaultStoreQuery(filterTags: [tag1])
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

        let query = VaultStoreQuery(filterTags: [tag1])
        let result = try await sut.retrieve(query: query)
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[0], insertedIDs[2]], "Matches both")
        XCTAssertEqual(result.errors, [])
    }

    func test_hasAnyItems_isFalseForNoItems() async throws {
        let value = try await sut.hasAnyItems

        XCTAssertFalse(value)
    }

    func test_hasAnyItems_returnsTrueForSingleItem() async throws {
        let code = anyOTPAuthCode().wrapInAnyVaultItem().makeWritable()
        try await sut.insert(item: code)

        let value = try await sut.hasAnyItems

        XCTAssertTrue(value)
    }

    func test_hasAnyItems_returnsTrueForSingleLockedItem() async throws {
        let code = anyOTPAuthCode().wrapInAnyVaultItem(visibility: .onlySearch, searchableLevel: .none).makeWritable()
        try await sut.insert(item: code)

        let value = try await sut.hasAnyItems

        XCTAssertTrue(value)
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

        let result = try await sut.retrieve(query: .init())
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

        let result = try await sut.retrieve(query: .init())
        XCTAssertEqual(result.items.map(\.id), ids)
        XCTAssertEqual(result.errors, [])
    }

    func test_insert_defaultRelativeOrderIsZero() async throws {
        let code = uniqueVaultItem().makeWritable()

        try await sut.insert(item: code)

        let result = try await sut.retrieve(query: .init())
        XCTAssertEqual(result.items.first?.metadata.relativeOrder, 0)
    }

    func test_deleteByID_hasNoEffectOnEmptyStore() async throws {
        try await sut.delete(id: .new())

        let result = try await sut.retrieve(query: .init())
        XCTAssertEqual(result.items, [])
        XCTAssertEqual(result.errors, [])
    }

    func test_deleteByID_deletesSingleEntryMatchingID() async throws {
        let code = uniqueVaultItem().makeWritable()

        let id = try await sut.insert(item: code)

        try await sut.delete(id: id)

        let result = try await sut.retrieve(query: .init())
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

        let result = try await sut.retrieve(query: .init())
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

        let result = try await sut.retrieve(query: .init())
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

        let result = try await sut.retrieve(query: .init())
        XCTAssertEqual(result.items.map(\.item.otpCode), codes.map(\.item.otpCode))
        XCTAssertEqual(result.errors, [])
    }

    func test_updateByID_updatesDataForValidCode() async throws {
        let initialCode = uniqueVaultItem().makeWritable()
        let id = try await sut.insert(item: initialCode)

        let newCode = uniqueVaultItem().makeWritable()
        try await sut.update(id: id, item: newCode)

        let result = try await sut.retrieve(query: .init())
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

        let result = try await sut.retrieve(query: .init())
        XCTAssertEqual(result.items.map(\.item.otpCode), initialCodes.map(\.item.otpCode) + [newCode.item.otpCode])
        XCTAssertEqual(result.errors, [])
    }

    func test_reorder_emptyItemsHasNoEffectOnEmptyStore() async throws {
        try await sut.reorder(items: [], to: .start)
    }

    func test_reorder_nonEmptyItemsHasNoEffectOnEmptyStore() async throws {
        try await sut.reorder(items: [.init(id: UUID())], to: .start)
    }

    func test_reorder_reorderToAfterThrowsErrorIfItemDoesNotExist() async throws {
        let code = uniqueVaultItem().makeWritable()
        let id = try await sut.insert(item: code)

        let sut = try XCTUnwrap(sut)
        await XCTAssertThrowsError(try await sut.reorder(
            items: [id],
            to: .after(.init(id: UUID()))
        ))
    }

    func test_reorder_reordersAllItemsIfMovingToStart() async throws {
        await sut.updateSortOrder(.relativeOrder)

        let codes = [
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
        ]
        var insertedIDs = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            // insert the id at the start because when using .relativeOrder, more recently created items are ordered
            // first
            insertedIDs.insert(id, at: 0)
        }

        try await sut.reorder(items: [insertedIDs[2]], to: .start)

        let result = try await sut.retrieve(query: .init())
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[2], insertedIDs[0], insertedIDs[1]])
        XCTAssertEqual(result.items.map(\.metadata.relativeOrder), [0, 1, 2])
        XCTAssertEqual(result.errors, [])
    }

    func test_reorder_reordersAllIfMovingToAfterOtherItem() async throws {
        await sut.updateSortOrder(.relativeOrder)

        let codes = [
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
            uniqueVaultItem().makeWritable(),
        ]
        var insertedIDs = [Identifier<VaultItem>]()
        for code in codes {
            let id = try await sut.insert(item: code)
            // insert the id at the start because when using .relativeOrder, more recently created items are ordered
            // first
            insertedIDs.insert(id, at: 0)
        }

        try await sut.reorder(items: [insertedIDs[0]], to: .after(insertedIDs[1]))

        let result = try await sut.retrieve(query: .init())
        XCTAssertEqual(result.items.map(\.metadata.id), [insertedIDs[1], insertedIDs[0], insertedIDs[2]])
        XCTAssertEqual(result.items.map(\.metadata.relativeOrder), [0, 1, 2])
        XCTAssertEqual(result.errors, [])
    }

    func test_exportVault_hasNoSideEffectsOnEmptyVault() async throws {
        _ = try await sut.exportVault(userDescription: "")

        let result = try await sut.retrieve(query: .init())
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

        let result = try await sut.retrieve(query: .init())
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
        let tags = [anyVaultItemTag(), anyVaultItemTag()]
        var insertedTagIDs = [Identifier<VaultItemTag>]()
        for tag in tags {
            let id = try await sut.insertTag(item: tag.makeWritable())
            insertedTagIDs.append(id)
        }

        let export = try await sut.exportVault(userDescription: "my description")

        XCTAssertEqual(export.userDescription, "my description")
        XCTAssertEqual(export.items.map { $0.makeWritable() }, items.map { $0.makeWritable() })
        XCTAssertEqual(export.items.map(\.id), insertedIDs)
        XCTAssertEqual(export.tags.map(\.id), insertedTagIDs)
    }

    func test_retrieveTags_returnsNoTagsIfThereAreNone() async throws {
        let tags = try await sut.retrieveTags()

        XCTAssertEqual(tags, [])
    }

    func test_retrieveTags_returnsMultipleTags() async throws {
        let items = [
            VaultItemTag.Write(name: "any1", color: .tagDefault, iconName: "any"),
            VaultItemTag.Write(name: "any2", color: .tagDefault, iconName: "any"),
            VaultItemTag.Write(name: "any3", color: .tagDefault, iconName: "any"),
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

    func test_deleteTag_removesFromModels() async throws {
        let otherTags = [
            anyVaultItemTag().makeWritable(),
            anyVaultItemTag().makeWritable(),
            anyVaultItemTag().makeWritable(),
        ]
        var insertedTagIds = [Identifier<VaultItemTag>]()
        for tag in otherTags {
            let id = try await sut.insertTag(item: tag)
            insertedTagIds.append(id)
        }

        let item1 = uniqueVaultItem(tags: insertedTagIds.reducedToSet()).makeWritable()
        let item2 = uniqueVaultItem(tags: [insertedTagIds[1], insertedTagIds[2]]).makeWritable()

        try await sut.insert(item: item1)
        try await sut.insert(item: item2)

        try await sut.deleteTag(id: insertedTagIds[0])

        let result = try await sut.retrieve(query: .init())
        let firstItem = result.items[0]
        XCTAssertEqual(firstItem.metadata.tags, [insertedTagIds[1], insertedTagIds[2]])
        let secondItem = result.items[1]
        XCTAssertEqual(secondItem.metadata.tags, [insertedTagIds[1], insertedTagIds[2]])
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

    func test_deleteVault_hasNoEffectOnEmptyStore() async throws {
        try await sut.deleteVault()

        try await assertStoreEmpty()
    }

    func test_deleteVault_removesAllItems() async throws {
        let tag1 = try await sut.insertTag(item: anyVaultItemTag().makeWritable())
        let tag2 = try await sut.insertTag(item: anyVaultItemTag().makeWritable())
        let codes: [VaultItem.Write] = [
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1, tag2]).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag2]).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag1, tag2]).makeWritable(),
            anyOTPAuthCode().wrapInAnyVaultItem(tags: [tag2]).makeWritable(),
        ]
        for code in codes {
            try await sut.insert(item: code)
        }

        try await sut.deleteVault()

        try await assertStoreEmpty()
    }

    func test_incrementCounter_throwsForNonTOTP() async throws {
        let note = anySecureNote().wrapInAnyVaultItem().makeWritable()
        let id1 = try await sut.insert(item: note)
        do {
            try await sut.incrementCounter(id: id1)
            XCTFail("Expected error")
        } catch {
            // expected
        }
    }

    func test_incrementCounter_incrementsHOTP() async throws {
        let code = anyOTPAuthCode(type: .hotp(counter: 12)).wrapInAnyVaultItem().makeWritable()
        let id1 = try await sut.insert(item: code)

        try await sut.incrementCounter(id: id1)

        let all = try await sut.retrieve(query: .init())
        let item = try XCTUnwrap(all.items.first)
        switch item.item.otpCode?.type {
        case let .hotp(counter): XCTAssertEqual(counter, 13)
        default: XCTFail("Expected hotp")
        }
    }

    func test_importAndMergeVault_importsEmptyToEmptyVault() async throws {
        let payload = VaultApplicationPayload(userDescription: "", items: [], tags: [])

        try await sut.importAndMergeVault(payload: payload)

        try await assertStoreEmpty()
    }

    func test_importAndMergeVault_emptyToNonEmptyVault() async throws {
        let item1 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 50))
        let item2 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 100))
        let item3 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 200))
        let items = [item1, item2, item3]
        let tag1 = anyVaultItemTag(name: "A")
        let tag2 = anyVaultItemTag(name: "B")
        let tags = [tag1, tag2]
        let payload1 = VaultApplicationPayload(
            userDescription: "Hello world",
            items: items,
            tags: tags
        )

        try await sut.importAndMergeVault(payload: payload1)

        let payload2 = VaultApplicationPayload(userDescription: "", items: [], tags: [])
        try await sut.importAndMergeVault(payload: payload2)

        try await assertStoreContains(exactlyItems: items)
        try await assertStoreContains(exactlyTags: tags)
    }

    func test_importAndMergeVault_importsNonEmptyToEmptyVault() async throws {
        let item1 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 50))
        let item2 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 100))
        let item3 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 200))
        let items = [item1, item2, item3]
        let tag1 = anyVaultItemTag(name: "A")
        let tag2 = anyVaultItemTag(name: "B")
        let tags = [tag1, tag2]
        let payload = VaultApplicationPayload(
            userDescription: "Hello world",
            items: items,
            tags: tags
        )

        try await sut.importAndMergeVault(payload: payload)

        try await assertStoreContains(exactlyItems: items)
        try await assertStoreContains(exactlyTags: tags)
    }

    func test_importAndMergeVault_importsNonEmptyToNonEmptyVault() async throws {
        let item1 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 50))
        let item2 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 100))
        let item3 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 200))
        let items1 = [item1, item2, item3]
        let tag1 = anyVaultItemTag(name: "A")
        let tag2 = anyVaultItemTag(name: "B")
        let tags1 = [tag1, tag2]
        let payload1 = VaultApplicationPayload(
            userDescription: "Hello world",
            items: items1,
            tags: tags1
        )

        try await sut.importAndMergeVault(payload: payload1)

        let item_a = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 400))
        let item_b = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 500))
        let item_c = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 600))
        let items2 = [item_a, item_b, item_c]
        let tag_c = anyVaultItemTag(name: "C")
        let tag_d = anyVaultItemTag(name: "D")
        let tags2 = [tag_c, tag_d]
        let payload2 = VaultApplicationPayload(
            userDescription: "Hello world",
            items: items2,
            tags: tags2
        )

        try await sut.importAndMergeVault(payload: payload2)

        try await assertStoreContains(exactlyItems: items1 + items2)
        try await assertStoreContains(exactlyTags: tags1 + tags2)
    }

    func test_importAndMergeVault_overridesItemWithSameIDAndLaterDate() async throws {
        let id1 = Identifier<VaultItem>.new()
        let item1 = uniqueVaultItem(id: id1, updatedDate: Date(timeIntervalSince1970: 50), userDescription: "ABC")
        let itemX = uniqueVaultItem()
        let id2 = UUID()
        let tag1 = anyVaultItemTag(id: id2, name: "A")
        let tagX = anyVaultItemTag(name: "N")
        let payload1 = VaultApplicationPayload(
            userDescription: "Hello world",
            items: [item1, itemX],
            tags: [tag1, tagX]
        )

        try await sut.importAndMergeVault(payload: payload1)

        let item2 = uniqueVaultItem(id: id1, updatedDate: Date(timeIntervalSince1970: 60), userDescription: "DEF")
        let tag2 = anyVaultItemTag(id: id2, name: "B")
        let payload2 = VaultApplicationPayload(
            userDescription: "Hello world",
            items: [item2],
            tags: [tag2]
        )

        try await sut.importAndMergeVault(payload: payload2)

        try await assertStoreContains(exactlyItems: [item2, itemX])
        try await assertStoreContains(exactlyTags: [tag2, tagX])
    }

    func test_importAndMergeVault_retainsExistingItemWithLaterUpdatedDate() async throws {
        let id1 = Identifier<VaultItem>.new()
        let item1 = uniqueVaultItem(id: id1, updatedDate: Date(timeIntervalSince1970: 60), userDescription: "ABC")
        let itemX = uniqueVaultItem()
        let id2 = UUID()
        let tag1 = anyVaultItemTag(id: id2, name: "A")
        let tagX = anyVaultItemTag(name: "N")
        let payload1 = VaultApplicationPayload(
            userDescription: "Hello world",
            items: [item1, itemX],
            tags: [tag1, tagX]
        )

        try await sut.importAndMergeVault(payload: payload1)

        let item2 = uniqueVaultItem(id: id1, updatedDate: Date(timeIntervalSince1970: 50), userDescription: "DEF")
        let tag2 = anyVaultItemTag(id: id2, name: "B")
        let payload2 = VaultApplicationPayload(
            userDescription: "Hello world",
            items: [item2],
            tags: [tag2]
        )

        try await sut.importAndMergeVault(payload: payload2)

        try await assertStoreContains(exactlyItems: [item1, itemX])
        try await assertStoreContains(
            exactlyTags: [tag2, tagX],
            message: "Tag is always updated, there is no date there."
        )
    }

    func test_importAndOverrideVault_importsEmptyToEmptyVault() async throws {
        let payload = VaultApplicationPayload(userDescription: "", items: [], tags: [])

        try await sut.importAndOverrideVault(payload: payload)

        try await assertStoreEmpty()
    }

    func test_importAndOverrideVault_importsEmptyToNonEmptyVault() async throws {
        let item1 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 50))
        let item2 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 100))
        let item3 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 200))
        let items = [item1, item2, item3]
        let tag1 = anyVaultItemTag(name: "A")
        let tag2 = anyVaultItemTag(name: "B")
        let tags = [tag1, tag2]
        let payload1 = VaultApplicationPayload(
            userDescription: "Hello world",
            items: items,
            tags: tags
        )

        try await sut.importAndMergeVault(payload: payload1)

        let payload2 = VaultApplicationPayload(userDescription: "", items: [], tags: [])

        try await sut.importAndOverrideVault(payload: payload2)

        try await assertStoreEmpty()
    }

    func test_importAndOverrideVault_importsNonEmptyToEmptyVault() async throws {
        let item1 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 50))
        let item2 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 100))
        let item3 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 200))
        let items = [item1, item2, item3]
        let tag1 = anyVaultItemTag(name: "A")
        let tag2 = anyVaultItemTag(name: "B")
        let tags = [tag1, tag2]
        let payload1 = VaultApplicationPayload(
            userDescription: "Hello world",
            items: items,
            tags: tags
        )

        try await sut.importAndOverrideVault(payload: payload1)

        try await assertStoreContains(exactlyItems: items)
        try await assertStoreContains(exactlyTags: tags)
    }

    func test_importAndOverrideVault_overridesExistingDataWithNew() async throws {
        let item1 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 50))
        let item2 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 100))
        let item3 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 200))
        let items = [item1, item2, item3]
        let tag1 = anyVaultItemTag(name: "A")
        let tag2 = anyVaultItemTag(name: "B")
        let tags = [tag1, tag2]
        let payload1 = VaultApplicationPayload(
            userDescription: "Hello world",
            items: items,
            tags: tags
        )

        try await sut.importAndOverrideVault(payload: payload1)

        let item4 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 50))
        let item5 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 100))
        let item6 = uniqueVaultItem(updatedDate: Date(timeIntervalSince1970: 200))
        let items2 = [item4, item5, item6]
        let tag4 = anyVaultItemTag(name: "C")
        let tag5 = anyVaultItemTag(name: "D")
        let tags2 = [tag4, tag5]
        let payload2 = VaultApplicationPayload(
            userDescription: "Hello world",
            items: items2,
            tags: tags2
        )

        try await sut.importAndOverrideVault(payload: payload2)

        try await assertStoreContains(exactlyItems: items2)
        try await assertStoreContains(exactlyTags: tags2)
    }
}

// MARK: - Helpers

extension PersistedLocalVaultStoreTests {
    private func assertStoreContains(item: VaultItem, file: StaticString = #filePath, line: UInt = #line) async throws {
        let allItems = try await sut.allVaultItems()
        let found = try XCTUnwrap(allItems.first(where: { $0.id == item.id }), "Item not in store")
        XCTAssertEqual(found, item, file: file, line: line)
    }

    private func assertStoreContains(
        exactlyItems: [VaultItem],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let allItems = try await sut.allVaultItems()
        XCTAssertEqual(
            allItems.sorted(by: { $0.metadata.updated < $1.metadata.updated }),
            exactlyItems.sorted(by: { $0.metadata.updated < $1.metadata.updated }),
            "Store does not contain exactly the specified items.",
            file: file,
            line: line
        )
    }

    private func assertStoreContains(
        exactlyTags: [VaultItemTag],
        message: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let allItems = try await sut.allVaultTags()
        XCTAssertEqual(
            allItems.sorted(by: { $0.name < $1.name }),
            exactlyTags.sorted(by: { $0.name < $1.name }),
            message ?? "Tags not equal",
            file: file,
            line: line
        )
    }

    private func assertStoreContains(
        tag: VaultItemTag,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let allItems = try await sut.allVaultTags()
        let found = try XCTUnwrap(allItems.first(where: { $0.id == tag.id }), "Tag not in store")
        XCTAssertEqual(found, tag, file: file, line: line)
    }

    private func assertStoreEmpty(file: StaticString = #filePath, line: UInt = #line) async throws {
        let allItems = try await sut.allVaultItems()
        let allTags = try await sut.allVaultTags()
        XCTAssertEqual(allItems, [], "Store is not empty!", file: file, line: line)
        XCTAssertEqual(allTags, [], "Store is not empty!", file: file, line: line)
    }
}

extension PersistedLocalVaultStore {
    fileprivate func allVaultItems() async throws -> [VaultItem] {
        let descriptor = FetchDescriptor<PersistedVaultItem>(predicate: .true)
        let result = try modelContext.fetch(descriptor)
        let decoder = PersistedVaultItemDecoder()
        return try result.map {
            try decoder.decode(item: $0)
        }
    }

    fileprivate func allVaultTags() async throws -> [VaultItemTag] {
        let descriptor = FetchDescriptor<PersistedVaultTag>(predicate: .true)
        let result = try modelContext.fetch(descriptor)
        let decoder = PersistedVaultTagDecoder()
        return try result.map {
            try decoder.decode(item: $0)
        }
    }

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

    func updateSortOrder(_ order: VaultStoreSortOrder) {
        sortOrder = order
    }
}
