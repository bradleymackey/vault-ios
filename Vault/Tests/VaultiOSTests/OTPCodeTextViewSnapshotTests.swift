import Combine
import SnapshotTesting
import SwiftUI
import VaultFeed
import XCTest
@testable import VaultiOS

final class OTPCodeTextViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = false
    }

    func test_visible_defaultCode() {
        let view = makeSUT(codeState: .visible("123456"))

        assertSnapshot(matching: view, as: .image)
    }

    func test_visible_staysOnSingleLineForLongCode() {
        let view = makeSUT(codeState: .visible("123456123456123456"))

        assertSnapshot(matching: view, as: .image)
    }

    func test_error_staysOnSingleLine() {
        let view = makeSUT(codeState: .error(.init(userTitle: "err", debugDescription: "err"), digits: 20))

        assertSnapshot(matching: view, as: .image)
    }

    func test_obfuscated_staysOnSingleLine() {
        let view = makeSUT(codeState: .obfuscated)

        assertSnapshot(matching: view, as: .image)
    }

    private func makeSUT(codeState: OTPCodeState) -> some View {
        OTPCodeTextView(codeState: codeState)
            .frame(width: 100, height: 100)
    }
}
