import Foundation
import XCTest
@testable import VaultCore

final class VaultItemTagTests: XCTestCase {
    func test_equal_onlyChecksIDs() {
        let id = makeUniqueIdentifier()
        XCTAssertEqual(
            VaultItemTag(id: id, name: "one"),
            VaultItemTag(id: id, name: "two")
        )

        XCTAssertNotEqual(
            VaultItemTag(id: makeUniqueIdentifier(), name: "one"),
            VaultItemTag(id: makeUniqueIdentifier(), name: "two")
        )
    }

    func test_hashable_onlyOnIds() {
        let id = makeUniqueIdentifier()
        let one = VaultItemTag(id: id, name: "one")
        let two = VaultItemTag(id: id, name: "two")
        XCTAssertEqual(
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
