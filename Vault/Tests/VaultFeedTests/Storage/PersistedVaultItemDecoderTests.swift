import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class PersistedVaultItemDecoderTests: XCTestCase {
    func test_decodeItem_missingItemDetail() throws {
        let sut = makeSUT()

        let persistedItem = makePersistedItem(
            noteDetails: nil,
            otpDetails: nil
        )

        XCTAssertThrowsError(try sut.decode(item: persistedItem))
    }
}

// MARK: - Helpers

extension PersistedVaultItemDecoderTests {
    private func makeSUT() -> PersistedVaultItemDecoder {
        PersistedVaultItemDecoder()
    }

    private func makePersistedItem(
        id: UUID = UUID(),
        createdDate: Date = Date(),
        updatedDate: Date = Date(),
        userDescription: String? = nil,
        colorBlue: Double? = nil,
        colorGreen: Double? = nil,
        colorRed: Double? = nil,
        noteDetails: PersistedNoteDetails? = nil,
        otpDetails: PersistedOTPDetails? = nil
    ) -> PersistedVaultItem {
        .init(
            id: id,
            createdDate: createdDate,
            updatedDate: updatedDate,
            userDescription: userDescription,
            colorBlue: colorBlue,
            colorGreen: colorGreen,
            colorRed: colorRed,
            noteDetails: noteDetails,
            otpDetails: otpDetails
        )
    }
}
