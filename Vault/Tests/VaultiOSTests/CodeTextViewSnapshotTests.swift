import Combine
import SnapshotTesting
import XCTest
@testable import VaultiOS

final class CodeTextViewSnapshotTests: XCTestCase {
    func test_visible_staysOnASingleLineIfNotEnoughSpace() {
        let view = OTPCodeTextView(codeState: .visible("123456"))
            .frame(width: 20, height: 100)

        assertSnapshot(matching: view, as: .image)
    }

    func test_error_staysOnSingleLine() {
        let view = OTPCodeTextView(codeState: .error(.init(userTitle: "err", debugDescription: "err"), digits: 30))
            .frame(width: 20, height: 100)

        assertSnapshot(matching: view, as: .image)
    }

    func test_obfuscated_staysOnSingleLine() {
        let view = OTPCodeTextView(codeState: .obfuscated)
            .frame(width: 20, height: 100)

        assertSnapshot(matching: view, as: .image)
    }
}
