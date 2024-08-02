import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class VaultItemTests: XCTestCase {
    func test_isContentEqual_comparesIDs() {
        let id = UUID()
        let item1 = makeVaultItem(id: id)
        let item2 = makeVaultItem(id: id)

        XCTAssertTrue(item1.isContentEqual(to: item2))

        let item3 = makeVaultItem(id: UUID())
        let item4 = makeVaultItem(id: UUID())

        XCTAssertFalse(item3.isContentEqual(to: item4))
    }

    func test_isContentEqual_comparesContent() {
        let id = UUID()
        let item1 = makeVaultItem(id: id, userDescription: "hello")
        let item2 = makeVaultItem(id: id, userDescription: "hello")

        XCTAssertTrue(item1.isContentEqual(to: item2))

        let item3 = makeVaultItem(id: id, userDescription: "NO")
        let item4 = makeVaultItem(id: id, userDescription: "YES")

        XCTAssertFalse(item3.isContentEqual(to: item4))
    }

    func test_isContentEqual_doesNotCompareCreatedDate() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1234)
        let item1 = makeVaultItem(id: id, created: date)
        let item2 = makeVaultItem(id: id, created: date)

        XCTAssertTrue(item1.isContentEqual(to: item2))

        let item3 = makeVaultItem(id: id, created: Date(timeIntervalSince1970: 10000))
        let item4 = makeVaultItem(id: id, created: Date(timeIntervalSince1970: 12345))

        XCTAssertTrue(item3.isContentEqual(to: item4), "Even though they differ, created date is not compared")
    }

    func test_isContentEqual_doesNotCompareUpdatedDate() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1234)
        let item1 = makeVaultItem(id: id, updated: date)
        let item2 = makeVaultItem(id: id, updated: date)

        XCTAssertTrue(item1.isContentEqual(to: item2))

        let item3 = makeVaultItem(id: id, updated: Date(timeIntervalSince1970: 10000))
        let item4 = makeVaultItem(id: id, updated: Date(timeIntervalSince1970: 12345))

        XCTAssertTrue(item3.isContentEqual(to: item4), "Even though they differ, updated date is not compared")
    }
}

// MARK: - Helpers

extension VaultItemTests {
    private func makeVaultItem(
        id: UUID,
        created: Date = Date(timeIntervalSince1970: 100),
        updated: Date = Date(timeIntervalSince1970: 200),
        relativeOrder: UInt64? = nil,
        userDescription: String = "Any",
        tags: Set<VaultItemTag.Identifier> = [],
        visibility: VaultItemVisibility = .always,
        searchableLevel: VaultItemSearchableLevel = .full,
        searchPassphrase: String? = nil,
        lockState: VaultItemLockState = .notLocked,
        color: VaultItemColor? = nil
    ) -> VaultItem {
        VaultItem(
            metadata: .init(
                id: id,
                created: created,
                updated: updated,
                relativeOrder: relativeOrder,
                userDescription: userDescription,
                tags: tags,
                visibility: visibility,
                searchableLevel: searchableLevel,
                searchPassphrase: searchPassphrase,
                lockState: lockState,
                color: color
            ),
            item: .secureNote(.init(title: "title", contents: "contents"))
        )
    }
}
