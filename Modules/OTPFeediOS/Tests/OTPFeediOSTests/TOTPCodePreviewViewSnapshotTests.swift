import Foundation
import OTPFeed
import SnapshotTesting
import SwiftUI
import XCTest
@testable import OTPFeediOS

@MainActor
final class TOTPCodePreviewViewSnapshotTests: XCTestCase {
    func test_layout_codeVisible() {
        let sut = makeSUT(state: .visible("123456"))

        assertSnapshot(matching: sut, as: .image)
    }

    func test_layout_codeError() {
        let error = PresentationError(userTitle: "userTitle", debugDescription: "debugDescription")
        let sut = makeSUT(state: .error(error, digits: 6))

        assertSnapshot(matching: sut, as: .image)
    }

    func test_layout_codeNotReady() {
        let sut = makeSUT(state: .notReady)

        assertSnapshot(matching: sut, as: .image)
    }

    func test_layout_noMoreCodes() {
        let sut = makeSUT(state: .finished)

        assertSnapshot(matching: sut, as: .image)
    }

    func test_textWrapping_longIssuerStaysOnASingleLine() {
        let sut = makeSUT(issuer: "This is a very long issuer which should be long because it is so long")

        assertSnapshot(matching: sut, as: .image)
    }

    func test_textWrapping_longAccountNameStaysOnASingleLine() {
        let sut = makeSUT(accountName: "This is a very long account name which should be long because it is so long")

        assertSnapshot(matching: sut, as: .image)
    }

    // MARK: - Helpers

    private func makeSUT(
        accountName: String = "Test",
        issuer: String = "Issuer",
        state: OTPCodeState = .visible("123456")
    ) -> some View {
        let preview = CodePreviewViewModel(accountName: accountName, issuer: issuer, fixedCodeState: state)
        return TOTPCodePreviewView(
            previewViewModel: preview,
            timerView: Rectangle().fill(Color.red),
            hideCode: false
        )
        .frame(width: 250, height: 150)
    }
}
