import SnapshotTesting
import SwiftUI
import XCTest
@testable import VaultiOS

final class LiteratureViewSnapshotTests: XCTestCase {
    @MainActor
    func test_layout_markdownText() {
        let view = NavigationStack {
            LiteratureView(title: "Title", bodyText: .markdown(.init("Body\n\nText\nTest")), bodyColor: .secondary)
        }
        .framedToTestDeviceSize()

        assertSnapshot(of: view, as: .image)
    }

    @MainActor
    func test_layout_rawText() {
        let view = NavigationStack {
            LiteratureView(title: "Title", bodyText: .raw("Body\n\nText\nTest"), bodyColor: .secondary)
        }
        .framedToTestDeviceSize()

        assertSnapshot(of: view, as: .image)
    }
}
