import Foundation
import ImageTools
import SnapshotTesting
import UIKit
import XCTest

final class UIImageResizerTests: XCTestCase {
    func test_resize_doesNotMakeImageBlurryResizingLarger() throws {
        let sut = makeSUT()
        let image = try exampleSmallImage()

        let resizedSmall = sut.resize(image: image, to: CGSize(width: 20, height: 20))
        assertSnapshot(matching: resizedSmall, as: .image, named: "small")

        let resizedMedium = sut.resize(image: image, to: CGSize(width: 100, height: 100))
        assertSnapshot(matching: resizedMedium, as: .image, named: "medium")

        let resizedLarge = sut.resize(image: image, to: CGSize(width: 250, height: 250))
        assertSnapshot(matching: resizedLarge, as: .image, named: "large")
    }

    // MARK: - Helpers

    private func makeSUT() -> UIImageResizer {
        UIImageResizer(mode: .noSmoothing)
    }

    private func exampleSmallImage() throws -> UIImage {
        let qr = QRCodeImageRenderer()
        let data = Data(repeating: 0xFF, count: 200)
        let image = try XCTUnwrap(qr.makeImage(fromData: data, size: nil))
        return image
    }
}
