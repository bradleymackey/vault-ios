import Foundation
import SnapshotTesting
import XCTest
@testable import VaultiOS

final class OpenSourceViewSnapshotTests: XCTestCase {
    @MainActor
    func test_deviceSize() {
        let view = OpenSourceView()
            .framedToTestDeviceSize()

        assertSnapshot(of: view, as: .image)
    }
}
