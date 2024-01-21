import Foundation
import PDFKit
import UIKit

public struct PDFDataBlockDocumentRenderer<
    ImageRenderer: PDFImageRenderer,
    RectLayout: RectSeriesLayout
>: PDFDocumentRenderer {
    public typealias Document = DataBlockDocument

    public let rendererFactory: any PDFRendererFactory
    public let imageRenderer: ImageRenderer
    public let blockLayout: (CGRect) -> RectLayout

    public init(
        rendererFactory: any PDFRendererFactory,
        imageRenderer: ImageRenderer,
        blockLayout: @escaping (CGRect) -> RectLayout
    ) {
        self.rendererFactory = rendererFactory
        self.imageRenderer = imageRenderer
        self.blockLayout = blockLayout
    }

    public func render(document: DataBlockDocument) throws -> PDFDocument {
        let renderer = rendererFactory.makeRenderer()
        let data = renderer.pdfData { context in
            let drawer = PDFDocumentDrawerHelper(context: context, headerGenerator: document.headerGenerator)
            drawer.startNextPage()
            for content in document.content {
                switch content {
                case let .title(label):
                    drawer.draw(label: label)
                case let .images(imageData):
                    drawer.draw(images: imageData, imageRenderer: imageRenderer, blockLayout: blockLayout)
                }
            }
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
    private let headerGenerator: any DataBlockHeaderGenerator
    private var currentVerticalOffset = 0.0
    private var currentImageNumberOnPage = 0
    private var currentPage = 0

    init(context: UIGraphicsPDFRendererContext, headerGenerator: any DataBlockHeaderGenerator) {
        self.context = context
        self.headerGenerator = headerGenerator
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

    func draw(images: [Data], imageRenderer: some PDFImageRenderer, blockLayout: (CGRect) -> some RectSeriesLayout) {
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
                } else {
                    // can't draw image, even on the next page.
                    // there probably just isn't enough space on the page, so ignore.
                    // FIXME: should this throw? probably
                }
            }
        }
    }

    func startNextPage() {
        context.beginPage()
        currentPage += 1
        currentVerticalOffset = 0.0
        currentImageNumberOnPage = 0

        drawHeaderIfNeeded()
    }

    private func drawHeaderIfNeeded() {
        guard let header = headerGenerator.makeHeader(pageNumber: currentPage) else { return }
        var labelHeights = [Double]()
        if let left = header.left {
            let (attributedString, rect) = renderedHeaderLabel(text: left, position: .left)
            attributedString.draw(in: rect)
            labelHeights.append(rect.height)
        }
        if let right = header.right {
            let (attributedString, rect) = renderedHeaderLabel(text: right, position: .right)
            attributedString.draw(in: rect)
            labelHeights.append(rect.height)
        }
        currentVerticalOffset += labelHeights.max() ?? 0.0
    }

    private func renderedHeaderLabel(text: String, position: HeaderPosition) -> (NSAttributedString, CGRect) {
        let labelInsetSize = 16.0
        let labelFontSize = 9.0
        let labelInsets = UIEdgeInsets(uniform: labelInsetSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = position.textAlignment
        paragraphStyle.lineBreakMode = position.lineBreakMode

        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: labelFontSize, weight: .regular),
                NSAttributedString.Key.foregroundColor: UIColor.darkGray,
            ]
        )
        let width = (context.pdfContextBounds.width / 2) - labelInsets.horizontalTotal
        let boundingRect = attributedString.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        )
        let textRect = CGRect(
            x: position.xPosition(width: width, insetSize: labelInsetSize),
            y: labelInsets.top,
            width: width,
            height: boundingRect.height + labelInsets.verticalTotal
        )
        return (attributedString, textRect)
    }

    /// Returns the first rect that fits in the page bounds or `nil`.
    private func getNextRectForImageOnPage(blockLayout: (CGRect) -> some RectSeriesLayout) -> CGRect? {
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

/// The position that a header label can be rendered in.
private enum HeaderPosition {
    case left, right

    var textAlignment: NSTextAlignment {
        switch self {
        case .left: .left
        case .right: .right
        }
    }

    var lineBreakMode: NSLineBreakMode {
        switch self {
        case .left: .byTruncatingTail
        case .right: .byTruncatingHead
        }
    }

    func xPosition(width: CGFloat, insetSize: CGFloat) -> CGFloat {
        switch self {
        case .left: insetSize // left's `.left` padding
        case .right: width
            + insetSize // left's `.left` padding
            + insetSize // left's `.right` padding
            + insetSize // right's `.left` padding
        }
    }
}
