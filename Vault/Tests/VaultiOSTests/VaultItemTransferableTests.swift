import Foundation
import Testing
import VaultFeed
@testable import VaultiOS

struct VaultItemTransferableTests {
    @Test
    func test_sharingContent_secureNoteIsTitle() {
        let item = anySecureNote(title: "my title")
        let clock = EpochClockMock(currentTime: 1234)
        let vaultItem = VaultItem(
            metadata: anyVaultItemMetadata(),
            item: .secureNote(item)
        )

        let sharingItem = vaultItem.sharingContent(clock: clock)

        #expect(sharingItem == "my title")
    }

    @Test
    func sharingContent_rendersTOTPCodeForTimestamp() throws {
        let item = try VaultItem(
            metadata: anyVaultItemMetadata(lockState: .notLocked),
            item: .otpCode(.init(
                type: .totp(period: 30),
                data: .init(secret: .base32EncodedString("AA"), accountName: "Test")
            ))
        )

        let sharingContent = item.sharingContent(clock: EpochClockMock(currentTime: 100))
        #expect(sharingContent == "887919")
    }

    @Test
    func sharingContent_rendersTOTPCodeForCounter() throws {
        let item = try VaultItem(
            metadata: anyVaultItemMetadata(lockState: .notLocked),
            item: .otpCode(.init(
                type: .hotp(counter: 3000),
                data: .init(secret: .base32EncodedString("AA"), accountName: "Test")
            ))
        )

        let sharingContent = item.sharingContent(clock: EpochClockMock(currentTime: 100))
        #expect(sharingContent == "020986")
    }

    @Test
    func sharingContent_rendersEmptyStringForLockedCode() throws {
        let item = try VaultItem(
            metadata: anyVaultItemMetadata(lockState: .lockedWithNativeSecurity),
            item: .otpCode(.init(
                type: .totp(period: 30),
                data: .init(secret: .base32EncodedString("AA"), accountName: "Test")
            ))
        )

        let sharingContent = item.sharingContent(clock: EpochClockMock(currentTime: 100))
        #expect(sharingContent == "")
    }
}
