import Foundation
import ImageTools
import SnapshotTesting
import UIKit
import XCTest

final class QRCodeImageRendererSnapshotTests: XCTestCase {
    func test_makeImage_generatesWithEmptyData() throws {
        let sut = makeSUT()

        let image = try XCTUnwrap(sut.makeImage(fromData: Data()))

        assertSnapshot(of: image, as: .image)
    }

    func test_makeImage_generatesWithSomeData() throws {
        let sut = makeSUT()

        let data = Data(repeating: 0xFF, count: 200)
        let image = try XCTUnwrap(sut.makeImage(fromData: data))

        assertSnapshot(of: image, as: .image)
    }
}

// MARK: - Helpers

extension QRCodeImageRendererSnapshotTests {
    private func makeSUT() -> QRCodeImageRenderer {
        QRCodeImageRenderer()
    }
}
