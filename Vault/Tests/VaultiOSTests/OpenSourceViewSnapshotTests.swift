import Foundation
import SnapshotTesting
import XCTest
@testable import VaultiOS

final class OpenSourceViewSnapshotTests: XCTestCase {
    @MainActor
    func test_deviceSize() {
        let view = OpenSourceView()
            .framedForTest()

        assertSnapshot(of: view, as: .image)
    }
}
