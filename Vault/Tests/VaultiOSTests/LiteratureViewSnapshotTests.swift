import SnapshotTesting
import SwiftUI
import XCTest
@testable import VaultiOS

final class LiteratureViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
//        isRecording = true
    }

    @MainActor
    func test_layout_bodyWithSecondaryText() {
        let view = NavigationStack {
            LiteratureView(title: "Title", bodyText: "Body\n\nText\nTest", bodyColor: .secondary)
        }
        .framedToTestDeviceSize()

        assertSnapshot(matching: view, as: .image)
    }
}
