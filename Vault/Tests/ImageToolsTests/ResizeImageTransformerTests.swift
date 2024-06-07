import Foundation
import ImageTools
import SnapshotTesting
import UIKit
import XCTest

final class ResizeImageTransformerTests: XCTestCase {
    func test_resize_doesNotMakeImageBlurryResizingLarger() throws {
        let image = try exampleImage()

        let sutSmall = makeSUT(size: CGSize(width: 20, height: 20))
        let resizedSmall = sutSmall.tranform(image: image)
        assertSnapshot(matching: resizedSmall, as: .image, named: "small")

        let sutMedium = makeSUT(size: CGSize(width: 100, height: 100))
        let resizedMedium = sutMedium.tranform(image: image)
        assertSnapshot(matching: resizedMedium, as: .image, named: "medium")

        let sutLarge = makeSUT(size: CGSize(width: 250, height: 250))
        let resizedLarge = sutLarge.tranform(image: image)
        assertSnapshot(matching: resizedLarge, as: .image, named: "large")
    }

    // MARK: - Helpers

    private func makeSUT(size: CGSize) -> ResizeImageTransformer {
        ResizeImageTransformer(size: size)
    }

    private func exampleImage() throws -> UIImage {
        let qr = QRCodeImageRenderer()
        let data = Data(repeating: 0xFF, count: 200)
        let image = try XCTUnwrap(qr.makeImage(fromData: data))
        return image
    }
}
