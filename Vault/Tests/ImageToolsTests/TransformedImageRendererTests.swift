import Foundation
import ImageTools
import TestHelpers
import XCTest

final class TransformedImageRendererTests: XCTestCase {
    func test_makeImage_nilFromRendererIsNil() {
        let renderer = ImageDataRendererMock()
        renderer.makeImageHandler = { _ in nil }
        let transformer = ImageTransformerMock()
        let sut = TransformedImageRenderer(renderer: renderer, transformer: transformer)

        XCTAssertNil(sut.makeImage(fromData: Data()))
    }

    func test_makeImage_appliesTransformOnce() {
        let imageData = Data(repeating: 0x44, count: 45)
        let renderer = ImageDataRendererMock()
        renderer.makeImageHandler = { _ in UIImage() }
        let transformer = ImageTransformerMock()
        let sut = TransformedImageRenderer(renderer: renderer, transformer: transformer)

        let image = sut.makeImage(fromData: imageData)

        XCTAssertNotNil(image)
        XCTAssertEqual(renderer.makeImageCallCount, 1)
        XCTAssertEqual(transformer.tranformCallCount, 1)
    }
}
