import Foundation
import OTPFeed
import SnapshotTesting
import SwiftUI
import XCTest
@testable import OTPFeediOS

@MainActor
final class TOTPCodePreviewViewSnapshotTests: XCTestCase {
    func test_fixedState_codeVisible() {
        let sut = makeSUT(fixedState: .visible("123456"))

        assertSnapshot(matching: sut, as: .image)
    }

    func test_fixedState_codeError() {
        let error = PresentationError(userTitle: "userTitle", debugDescription: "debugDescription")
        let sut = makeSUT(fixedState: .error(error, digits: 6))

        assertSnapshot(matching: sut, as: .image)
    }

    func test_fixedState_codeNotReady() {
        let sut = makeSUT(fixedState: .notReady)

        assertSnapshot(matching: sut, as: .image)
    }

    func test_fixedState_noMoreCodes() {
        let sut = makeSUT(fixedState: .finished)

        assertSnapshot(matching: sut, as: .image)
    }

    // MARK: - Helpers

    private func makeSUT(fixedState: OTPCodeState) -> some View {
        let preview = CodePreviewViewModel(accountName: "Test", issuer: "Issuer", fixedCodeState: fixedState)
        return TOTPCodePreviewView(
            previewViewModel: preview,
            timerView: Rectangle().fill(Color.red),
            hideCode: false
        )
        .frame(width: 250, height: 150)
    }
}
