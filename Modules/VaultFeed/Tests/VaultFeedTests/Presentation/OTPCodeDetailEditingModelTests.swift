import Foundation
import XCTest
@testable import VaultFeed

@MainActor
final class OTPCodeDetailEditingModelTests: XCTestCase {
    func test_isDirty_initiallyFalse() {
        let detail = OTPCodeDetailEdits()
        let sut = makeSUT(detail: detail)

        XCTAssertFalse(sut.isDirty)
    }

    func test_isDirty_resetsOncePersisted() async throws {
        let detail = OTPCodeDetailEdits(
            issuerTitle: "hello"
        )
        let sut = makeSUT(detail: detail)

        sut.detail.issuerTitle = "next"
        XCTAssertTrue(sut.isDirty)
        sut.didPersist()
        XCTAssertFalse(sut.isDirty)
    }
}

extension OTPCodeDetailEditingModelTests {
    private func makeSUT(
        detail: OTPCodeDetailEdits
    ) -> OTPCodeDetailEditingModel {
        OTPCodeDetailEditingModel(detail: detail)
    }
}
