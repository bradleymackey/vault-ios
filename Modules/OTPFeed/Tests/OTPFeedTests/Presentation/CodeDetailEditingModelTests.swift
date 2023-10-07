import Foundation
import XCTest
@testable import OTPFeed

@MainActor
final class CodeDetailEditingModelTests: XCTestCase {
    func test_isDirty_initiallyFalse() {
        let detail = CodeDetailEdits()
        let sut = makeSUT(detail: detail)

        XCTAssertFalse(sut.isDirty)
    }

    func test_didPersist_publishesUpdatedState() async throws {
        let detail = CodeDetailEdits(
            issuerTitle: "hello"
        )
        let sut = makeSUT(detail: detail)

        let publisher = sut.$detail.collectNext(2)
        let values = try await awaitPublisher(publisher) {
            sut.detail.issuerTitle = "next"
            sut.didPersist()
        }

        XCTAssertEqual(values.map(\.issuerTitle), [
            "next", // changed
            "next", // didPersist
        ])
    }
}

extension CodeDetailEditingModelTests {
    private func makeSUT(
        detail: CodeDetailEdits
    ) -> CodeDetailEditingModel {
        CodeDetailEditingModel(detail: detail)
    }
}
