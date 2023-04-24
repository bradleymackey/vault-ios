import Foundation
import PDFKit
import UIKit

public struct PDFDataBlockDocumentRenderer<
    RendererFactory: PDFRendererFactory,
    ImageRenderer: PDFImageRenderer,
    BlockLayout: PDFDataBlockLayout
>: PDFDocumentRenderer {
    public typealias Document = DataBlockExportDocument

    public let rendererFactory: RendererFactory
    public let imageRenderer: ImageRenderer
    public let blockLayout: (CGRect) -> BlockLayout

    public init(
        rendererFactory: RendererFactory,
        imageRenderer: ImageRenderer,
        blockLayout: @escaping (CGRect) -> BlockLayout
    ) {
        self.rendererFactory = rendererFactory
        self.imageRenderer = imageRenderer
        self.blockLayout = blockLayout
    }

    public func render(document: DataBlockExportDocument) -> PDFDocument? {
        let renderer = rendererFactory.makeRenderer()
        let data = renderer.pdfData { context in
            let drawer = PDFDocumentDrawerHelper(context: context)
            drawer.startNextPage()
            if let title = document.title {
                drawer.draw(label: title)
            }
            if let subtitle = document.subtitle {
                drawer.draw(label: subtitle)
            }
            drawer.draw(images: document.dataBlockImageData, imageRenderer: imageRenderer, blockLayout: blockLayout)
        }
        return PDFDocument(data: data)
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
        var blockLayoutEngine = blockLayout(
            context.pdfContextBounds.inset(by: UIEdgeInsets(top: currentVerticalOffset, left: 0, bottom: 0, right: 0))
        )
        for imageData in images {
            defer { currentImageNumberOnPage += 1 }
            var desiredRect = blockLayoutEngine.rect(atIndex: UInt(currentImageNumberOnPage))
            if !blockLayoutEngine.isFullyWithinBounds(rect: desiredRect) {
                startNextPage()
                blockLayoutEngine = blockLayout(
                    context.pdfContextBounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
                )
                currentImageNumberOnPage = 0
                desiredRect = blockLayoutEngine.rect(atIndex: UInt(currentImageNumberOnPage))
            }
            let image = imageRenderer.makeImage(fromData: imageData, size: desiredRect.size)
            image?.draw(in: desiredRect)
        }
    }

    func startNextPage() {
        context.beginPage()
        currentVerticalOffset = 0.0
    }

    private func renderedLabel(for label: DataBlockLabel, pageRect: CGRect, textTop: CGFloat) -> (NSAttributedString, CGRect) {
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
