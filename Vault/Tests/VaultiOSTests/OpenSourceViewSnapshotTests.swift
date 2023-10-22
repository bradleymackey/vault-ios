import Foundation
import SnapshotTesting
import XCTest
@testable import VaultiOS

final class OpenSourceViewSnapshotTests: XCTestCase {
    func test_deviceSize() {
        let view = OpenSourceView()
            .framedToTestDeviceSize()

        assertSnapshot(matching: view, as: .image)
    }
}
