import Foundation
import ImageTools
import TestHelpers
import Testing
import UIKit
import VaultExport

struct PDFDataBlockDocumentRendererUnitTests {
    @Test
    func init_rendersNoImages() {
        let imageRenderer = makeImageRenderer()

        _ = makeSUT(imageRenderer: imageRenderer)

        #expect(imageRenderer.makeImageCallCount == 0)
    }

    @Test
    func init_rendersNoBlocks() {
        let layoutSpy = LayoutSpy()

        _ = makeSUT(rectLayout: layoutSpy)

        #expect(!layoutSpy.rectAtIndexCalled)
    }

    @Test
    func render_makesSingleRendererFromFactory() throws {
        let rendererFactory = makeRendererFactory()
        let sut = makeSUT(rendererFactory: rendererFactory)

        _ = try? sut.render(document: anyDataBlockExportDocument())

        #expect(rendererFactory.makeRendererCallCount == 1)
    }

    @Test
    func render_returnsPDFDocumentForValidData() {
        let renderer = UIGraphicsPDFRenderer(bounds: .init())
        let rendererFactory = makeRendererFactory(renderer: renderer)
        let sut = makeSUT(rendererFactory: rendererFactory)

        #expect(throws: Never.self) {
            try sut.render(document: anyDataBlockExportDocument())
        }
    }

    @Test
    func render_throwsForInvalidPDFData() {
        let renderer = UIGraphicsPDFRendererStub()
        renderer.pdfDataValue = makeInvalidPDFData()
        let rendererFactory = makeRendererFactory(renderer: renderer)
        let sut = makeSUT(rendererFactory: rendererFactory)

        #expect(throws: (any Error).self) {
            try sut.render(document: anyDataBlockExportDocument())
        }
    }
}

// MARK: - Helpers

extension PDFDataBlockDocumentRendererUnitTests {
    private func makeSUT(
        rendererFactory: PDFRendererFactoryMock = makeRendererFactory(),
        imageRenderer: ImageDataRendererMock = makeImageRenderer(),
        rectLayout: LayoutSpy = LayoutSpy()
    ) -> PDFDataBlockDocumentRenderer<ImageDataRendererMock, LayoutSpy> {
        PDFDataBlockDocumentRenderer(
            documentSize: USLetterDocumentSize(),
            rendererFactory: rendererFactory,
            imageRenderer: imageRenderer,
            blockLayout: { _ in rectLayout }
        )
    }

    private func anyDataBlockExportDocument() -> DataBlockDocument {
        DataBlockDocument(
            headerGenerator: DataBlockHeaderGeneratorMock(),
            content: []
        )
    }

    private func makeInvalidPDFData() -> Data {
        // empty data consistutes an invalid PDF document - at least at the time of writing
        Data()
    }
}

private class LayoutSpy: RectSeriesLayout, PageLayout {
    var rectAtIndexCalled = false
    func rect(atIndex _: UInt) -> CGRect? {
        rectAtIndexCalled = true
        return .init(origin: .zero, size: .zero)
    }

    var spacing: CGFloat = 5.0

    func isFullyWithinBounds(rect _: CGRect) -> Bool {
        false
    }
}

private func makeImageRenderer() -> ImageDataRendererMock {
    let stub = ImageDataRendererMock()
    stub.makeImageHandler = { _ in nil }
    return stub
}

private func makeRendererFactory(renderer: UIGraphicsPDFRenderer = UIGraphicsPDFRendererStub())
    -> PDFRendererFactoryMock
{
    let stub = PDFRendererFactoryMock()
    stub.makeRendererHandler = { renderer }
    return stub
}
