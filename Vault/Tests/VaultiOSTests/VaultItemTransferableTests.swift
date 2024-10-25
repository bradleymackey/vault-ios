import Foundation
import Testing
import VaultFeed
@testable import VaultiOS

struct VaultItemTransferableTests {
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
