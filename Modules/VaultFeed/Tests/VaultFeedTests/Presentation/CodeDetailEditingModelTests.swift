import Foundation
import XCTest
@testable import VaultFeed

@MainActor
final class CodeDetailEditingModelTests: XCTestCase {
    func test_isDirty_initiallyFalse() {
        let detail = CodeDetailEdits()
        let sut = makeSUT(detail: detail)

        XCTAssertFalse(sut.isDirty)
    }

    func test_isDirty_resetsOncePersisted() async throws {
        let detail = CodeDetailEdits(
            issuerTitle: "hello"
        )
        let sut = makeSUT(detail: detail)

        sut.detail.issuerTitle = "next"
        XCTAssertTrue(sut.isDirty)
        sut.didPersist()
        XCTAssertFalse(sut.isDirty)
    }
}

extension CodeDetailEditingModelTests {
    private func makeSUT(
        detail: CodeDetailEdits
    ) -> CodeDetailEditingModel {
        CodeDetailEditingModel(detail: detail)
    }
}
