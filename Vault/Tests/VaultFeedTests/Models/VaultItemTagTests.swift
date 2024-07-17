import Foundation
import XCTest
@testable import VaultFeed

final class VaultItemTagTests: XCTestCase {
    func test_equal_checksWholeObject() {
        let id = makeUniqueIdentifier()
        XCTAssertEqual(
            VaultItemTag(id: id, name: "same"),
            VaultItemTag(id: id, name: "same")
        )

        XCTAssertNotEqual(
            VaultItemTag(id: id, name: "one"),
            VaultItemTag(id: id, name: "two")
        )

        XCTAssertNotEqual(
            VaultItemTag(id: makeUniqueIdentifier(), name: "one"),
            VaultItemTag(id: makeUniqueIdentifier(), name: "two")
        )
    }

    func test_hashable_onWholeObject() {
        let id = makeUniqueIdentifier()
        XCTAssertEqual(
            VaultItemTag(id: id, name: "same").hashValue,
            VaultItemTag(id: id, name: "same").hashValue
        )

        let one = VaultItemTag(id: id, name: "one")
        let two = VaultItemTag(id: id, name: "two")
        XCTAssertNotEqual(
            one.hashValue,
            two.hashValue
        )

        XCTAssertNotEqual(
            VaultItemTag(id: makeUniqueIdentifier(), name: "one").hashValue,
            VaultItemTag(id: makeUniqueIdentifier(), name: "two").hashValue
        )
    }
}

// MARK: - Helpers

extension VaultItemTagTests {
    private func makeUniqueIdentifier() -> VaultItemTag.Identifier {
        .init(id: UUID())
    }
}
