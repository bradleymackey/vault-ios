import Foundation
import ImageTools
import SnapshotTesting
import UIKit
import XCTest

final class QRCodeGeneratorSnapshotTests: XCTestCase {
    func test_generatePNG_generatesPNGWithEmptyData() throws {
        let sut = makeSUT()

        let imageData = try XCTUnwrap(sut.generatePNG(data: Data()))

        let image = try imageForSnapshotting(pngData: imageData)
        assertSnapshot(matching: image, as: .image)
    }

    func test_generatePNG_generatesPNGWithNonEmptyData() throws {
        let sut = makeSUT()

        let data = Data(repeating: 0xFF, count: 200)
        let imageData = try XCTUnwrap(sut.generatePNG(data: data))

        let image = try imageForSnapshotting(pngData: imageData)
        assertSnapshot(matching: image, as: .image)
    }

    // MARK: - Helpers

    private func makeSUT() -> QRCodeGenerator {
        QRCodeGenerator()
    }

    private func imageForSnapshotting(pngData: Data) throws -> UIImage {
        try XCTUnwrap(UIImage(data: pngData))
    }
}
