import Foundation
import TestHelpers
import VaultFeed
import XCTest
@testable import VaultiOS

final class DraggableItemTests: XCTestCase {
    func test_sharingContent_secureNoteIsTitle() {
        let item = anySecureNote(title: "my title")
        let clock = EpochClockMock(currentTime: 1234)
        let vaultItem = VaultItem(
            metadata: anyVaultItemMetadata(),
            item: .secureNote(item)
        )

        let sharingItem = vaultItem.sharingContent(clock: clock)

        XCTAssertEqual(sharingItem, "my title")
    }

    func test_sharingContent_totpCodeIsCode() {
        let item = anyOTPVaultItem(
            type: .totp(period: 30),
            secret: .empty(),
            algorithm: .sha256,
            digits: .init(value: 6)
        )
        let clock = EpochClockMock(currentTime: 1234)

        let sharingItem = item.sharingContent(clock: clock)

        XCTAssertEqual(sharingItem, "795374")
    }

    func test_sharingContent_hotpCodeIsCode() {
        let item = anyOTPVaultItem(
            type: .hotp(counter: 30),
            secret: .empty(),
            algorithm: .sha256,
            digits: .init(value: 6)
        )
        let clock = EpochClockMock(currentTime: 1234)

        let sharingItem = item.sharingContent(clock: clock)

        XCTAssertEqual(sharingItem, "531626")
    }
}
