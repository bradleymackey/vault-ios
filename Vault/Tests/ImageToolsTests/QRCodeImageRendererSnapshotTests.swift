import Foundation
import ImageTools
import SnapshotTesting
import UIKit
import XCTest

final class QRCodeImageRendererSnapshotTests: XCTestCase {
    func test_makeImage_generatesNaturalSizeWithEmptyData() throws {
        let sut = makeSUT()

        let image = try XCTUnwrap(sut.makeImage(fromData: Data(), size: nil))

        assertSnapshot(matching: image, as: .image)
    }

    func test_makeImage_generatesNaturalSizeWithSomeData() throws {
        let sut = makeSUT()

        let data = Data(repeating: 0xFF, count: 200)
        let image = try XCTUnwrap(sut.makeImage(fromData: data, size: nil))

        assertSnapshot(matching: image, as: .image)
    }

    func test_makeImage_generatesResizedWithSomeData() throws {
        let sut = makeSUT()

        let data = Data(repeating: 0xFF, count: 200)
        let image = try XCTUnwrap(sut.makeImage(fromData: data, size: CGSize(width: 200, height: 200)))

        assertSnapshot(matching: image, as: .image)
    }
}

// MARK: - Helpers

extension QRCodeImageRendererSnapshotTests {
    private func makeSUT() -> QRCodeImageRenderer {
        QRCodeImageRenderer()
    }
}
