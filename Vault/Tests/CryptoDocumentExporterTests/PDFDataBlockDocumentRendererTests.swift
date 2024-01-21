import CryptoDocumentExporter
import Foundation
import TestHelpers
import XCTest

final class PDFDataBlockDocumentRendererTests: XCTestCase {
    func test_init_rendersNoImages() {
        let imageRenderer = makeImageRenderer()

        _ = makeSUT(imageRenderer: imageRenderer)

        XCTAssertFalse(imageRenderer.makeImageFromDataSizeCalled)
    }

    func test_init_rendersNoBlocks() {
        let blockLayout = makeBlockLayout()

        _ = makeSUT(blockLayout: blockLayout)

        XCTAssertFalse(blockLayout.rectAtIndexCalled)
    }

    func test_render_makesSingleRendererFromFactory() throws {
        let rendererFactory = makeRendererFactory()
        let sut = makeSUT(rendererFactory: rendererFactory)

        _ = try? sut.render(document: anyDataBlockExportDocument())

        XCTAssertEqual(rendererFactory.makeRendererCallsCount, 1)
    }

    func test_render_returnsPDFDocumentForValidData() {
        let renderer = UIGraphicsPDFRenderer(bounds: .init())
        let rendererFactory = makeRendererFactory(renderer: renderer)
        let sut = makeSUT(rendererFactory: rendererFactory)

        XCTAssertNoThrow(try sut.render(document: anyDataBlockExportDocument()))
    }

    func test_render_throwsForInvalidPDFData() {
        let renderer = UIGraphicsPDFRendererStub()
        renderer.pdfDataValue = makeInvalidPDFData()
        let rendererFactory = makeRendererFactory(renderer: renderer)
        let sut = makeSUT(rendererFactory: rendererFactory)

        XCTAssertThrowsError(try sut.render(document: anyDataBlockExportDocument()))
    }
}

// MARK: - Helpers

extension PDFDataBlockDocumentRendererTests {
    private func makeSUT(
        rendererFactory: RendererFactory = makeRendererFactory(),
        imageRenderer: ImageRenderer = makeImageRenderer(),
        blockLayout: BlockLayout = makeBlockLayout()
    ) -> PDFDataBlockDocumentRenderer<ImageRenderer, BlockLayout> {
        PDFDataBlockDocumentRenderer(
            rendererFactory: rendererFactory,
            imageRenderer: imageRenderer,
            blockLayout: { _ in blockLayout }
        )
    }

    private func anyDataBlockExportDocument() -> DataBlockDocument {
        DataBlockDocument(titles: [], dataBlockImageData: [])
    }

    private func makeInvalidPDFData() -> Data {
        // empty data consistutes an invalid PDF document - at least at the time of writing
        Data()
    }
}

private typealias ImageRenderer = PDFImageRendererSpy
private typealias BlockLayout = PDFDataBlockLayoutSpy
private typealias RendererFactory = PDFRendererFactorySpy

private func makeImageRenderer() -> ImageRenderer {
    let stub = ImageRenderer()
    stub.makeImageFromDataSizeReturnValue = nil
    return stub
}

private func makeBlockLayout() -> BlockLayout {
    let stub = BlockLayout()
    stub.rectAtIndexReturnValue = CGRect(origin: .zero, size: .zero)
    return stub
}

private func makeRendererFactory(renderer: UIGraphicsPDFRenderer = UIGraphicsPDFRendererStub()) -> RendererFactory {
    let stub = RendererFactory()
    stub.makeRendererReturnValue = renderer
    return stub
}
