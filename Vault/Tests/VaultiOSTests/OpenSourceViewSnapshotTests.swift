import Foundation
import TestHelpers
import Testing
@testable import VaultiOS

@Suite
@MainActor
final class OpenSourceViewSnapshotTests {
    @Test
    func deviceSize() {
        let view = OpenSourceView()
            .framedForTest()

        assertSnapshot(of: view, as: .image)
    }
}
