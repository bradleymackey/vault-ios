import Foundation
import XCTest
@testable import VaultFeed

final class DetailEditingModelTests: XCTestCase {
    func test_isDirty_initiallyFalse() {
        let sut = makeSUT(detail: .init(value: "hello"))

        XCTAssertFalse(sut.isDirty)
    }

    func test_isDirty_resetsOncePersisted() async throws {
        var sut = makeSUT(detail: .init(value: "hello"))

        sut.detail.value = "next"
        XCTAssertTrue(sut.isDirty)
        sut.didPersist()
        XCTAssertFalse(sut.isDirty)
    }
}

extension DetailEditingModelTests {
    typealias SUT = DetailEditingModel<EditableStateMock>

    private func makeSUT(detail: EditableStateMock) -> SUT {
        SUT(detail: detail)
    }

    struct EditableStateMock: EditableState {
        var value: String
        var isValid: Bool { true }
    }
}
