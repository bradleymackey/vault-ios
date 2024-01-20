import Foundation
import PDFKit
import UIKit

public struct PDFDataBlockDocumentRenderer<
    ImageRenderer: PDFImageRenderer,
    BlockLayout: PDFDataBlockLayout
>: PDFDocumentRenderer {
    public typealias Document = DataBlockExportDocument

    public let rendererFactory: any PDFRendererFactory
    public let imageRenderer: ImageRenderer
    public let blockLayout: (CGRect) -> BlockLayout

    public init(
        rendererFactory: any PDFRendererFactory,
        imageRenderer: ImageRenderer,
        blockLayout: @escaping (CGRect) -> BlockLayout
    ) {
        self.rendererFactory = rendererFactory
        self.imageRenderer = imageRenderer
        self.blockLayout = blockLayout
    }

    public func render(document: DataBlockExportDocument) throws -> PDFDocument {
        let renderer = rendererFactory.makeRenderer()
        let data = renderer.pdfData { context in
            let drawer = PDFDocumentDrawerHelper(context: context)
            drawer.startNextPage()
            for title in document.titles {
                drawer.draw(label: title)
            }
            drawer.draw(images: document.dataBlockImageData, imageRenderer: imageRenderer, blockLayout: blockLayout)
        }
        if let document = PDFDocument(data: data) {
            return document
        } else {
            throw PDFRenderingError.invalidData
        }
    }
}

private final class PDFDocumentDrawerHelper {
    let context: UIGraphicsPDFRendererContext
    private var currentVerticalOffset = 0.0
    private var currentImageNumberOnPage = 0

    init(context: UIGraphicsPDFRendererContext) {
        self.context = context
    }

    func draw(label: DataBlockLabel) {
        let (attributedString, rect) = renderedLabel(
            for: label,
            pageRect: context.pdfContextBounds,
            textTop: currentVerticalOffset
        )
        attributedString.draw(in: rect)
        currentVerticalOffset += label.padding.top
        currentVerticalOffset += rect.height
    }

    func draw(images: [Data], imageRenderer: some PDFImageRenderer, blockLayout: (CGRect) -> some PDFDataBlockLayout) {
        for imageData in images {
            defer { currentImageNumberOnPage += 1 }
            if let imageRect = getNextRectForImageOnPage(blockLayout: blockLayout) {
                let image = imageRenderer.makeImage(fromData: imageData, size: imageRect.size)
                image?.draw(in: imageRect)
            } else {
                startNextPage()
                if let imageRect = getNextRectForImageOnPage(blockLayout: blockLayout) {
                    let image = imageRenderer.makeImage(fromData: imageData, size: imageRect.size)
                    image?.draw(in: imageRect)
                }
            }
        }
    }

    func startNextPage() {
        context.beginPage()
        currentVerticalOffset = 0.0
        currentImageNumberOnPage = 0
    }

    /// Returns the first rect that fits in the page bounds or `nil`.
    private func getNextRectForImageOnPage(blockLayout: (CGRect) -> some PDFDataBlockLayout) -> CGRect? {
        let currentInsets = UIEdgeInsets(top: currentVerticalOffset, left: 0, bottom: 0, right: 0)
        let currentLayoutEngine = blockLayout(
            context.pdfContextBounds.inset(by: currentInsets)
        )
        return currentLayoutEngine.rect(atIndex: UInt(currentImageNumberOnPage))
    }

    private func renderedLabel(
        for label: DataBlockLabel,
        pageRect: CGRect,
        textTop: CGFloat
    ) -> (NSAttributedString, CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributedText = NSAttributedString(
            string: label.text,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: label.font,
            ]
        )
        let width = pageRect.width - label.padding.horizontalTotal
        let boundingRect = attributedText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        )
        let textRect = CGRect(
            x: label.padding.left,
            y: textTop + label.padding.top,
            width: width,
            height: boundingRect.height + label.padding.bottom
        )
        return (attributedText, textRect)
    }
}
