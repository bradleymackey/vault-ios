import SnapshotTesting
import SwiftUI
import Testing
@testable import VaultiOS

@Suite
@MainActor
final class LiteratureViewSnapshotTests {
    @Test
    func layout_markdownText() {
        let view = NavigationStack {
            LiteratureView(title: "Title", bodyText: .markdown(.init("Body\n\nText\nTest")), bodyColor: .secondary)
        }
        .framedForTest()

        assertSnapshot(of: view, as: .image)
    }

    @Test
    func layout_rawText() {
        let view = NavigationStack {
            LiteratureView(title: "Title", bodyText: .raw("Body\n\nText\nTest"), bodyColor: .secondary)
        }
        .framedForTest()

        assertSnapshot(of: view, as: .image)
    }
}
