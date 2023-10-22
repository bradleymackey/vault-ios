import Foundation
import XCTest
@testable import VaultFeed

@MainActor
final class DetailEditingModelTests: XCTestCase {
    func test_isDirty_initiallyFalse() {
        let sut = makeSUT(detail: "hello")

        XCTAssertFalse(sut.isDirty)
    }

    func test_isDirty_resetsOncePersisted() async throws {
        var sut = makeSUT(detail: "hello")

        sut.detail = "next"
        XCTAssertTrue(sut.isDirty)
        sut.didPersist()
        XCTAssertFalse(sut.isDirty)
    }
}

extension DetailEditingModelTests {
    typealias SUT = DetailEditingModel<String>

    private func makeSUT(detail: String) -> SUT {
        SUT(detail: detail)
    }
}
