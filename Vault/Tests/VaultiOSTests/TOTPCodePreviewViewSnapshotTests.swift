import Foundation
import SnapshotTesting
import SwiftUI
import VaultFeed
import XCTest
@testable import VaultiOS

final class TOTPCodePreviewViewSnapshotTests: XCTestCase {
    @MainActor
    func test_layout_codeVisible() {
        let sut = makeSUT(state: .visible("123456"))

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_layout_codeError() {
        let error = PresentationError(userTitle: "userTitle", debugDescription: "debugDescription")
        let sut = makeSUT(state: .error(error, digits: 6))

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_layout_codeNotReady() {
        let sut = makeSUT(state: .notReady)

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_layout_noMoreCodes() {
        let sut = makeSUT(state: .finished)

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_layout_obfuscateWithoutMessage() {
        let sut = makeSUT(state: .visible("123456"), behaviour: .editingState(message: nil))

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_layout_obfuscateWithMessage() {
        let sut = makeSUT(state: .visible("123456"), behaviour: .editingState(message: "Custom message"))

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_layout_obfuscateWithLongMessage() {
        let sut = makeSUT(state: .visible("123456"), behaviour: .editingState(message: longMessage()))

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_textWrapping_longCodeMaintainsSameSizeForAllDigits() {
        let digits = [6, 7, 8, 20]
        for count in digits {
            let code = String(Array(repeating: Character("0"), count: count))
            let sut = makeSUT(state: .visible(code))

            assertSnapshot(of: sut, as: .image, named: "\(count)-digits")
        }
    }

    @MainActor
    func test_textWrapping_longIssuerStaysOnTwoLines() {
        let sut = makeSUT(issuer: longMessage())

        assertSnapshot(of: sut, as: .image)
    }

    @MainActor
    func test_textWrapping_longAccountNameStaysOnTwoLines() {
        let sut = makeSUT(accountName: longMessage())

        assertSnapshot(of: sut, as: .image)
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT(
        accountName: String = "Test",
        issuer: String = "Issuer",
        state: OTPCodeState = .visible("123456"),
        behaviour: VaultItemViewBehaviour = .normal,
    ) -> some View {
        let preview = OTPCodePreviewViewModel(
            accountName: accountName,
            issuer: issuer,
            color: .default,
            isLocked: false,
            fixedCodeState: state,
        )
        return TOTPCodePreviewView(
            previewViewModel: preview,
            timerView: testTimerGradient(),
            behaviour: behaviour,
        )
        .frame(width: 250)
    }

    /// We use this specific gradient for the default timer so it's very clear if it's been overridden.
    private func testTimerGradient() -> some View {
        LinearGradient(colors: [.red, .blue, .green], startPoint: .leading, endPoint: .trailing)
    }

    private func longMessage() -> String {
        """
        This is a very long string which should be long because it is so long \
        This is a very long string which should be long because it is so long \
        This is a very long string which should be long because it is so long
        """
    }
}
