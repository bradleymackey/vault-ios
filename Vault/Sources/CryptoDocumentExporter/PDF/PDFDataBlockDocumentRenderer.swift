import Foundation
import PDFKit
import UIKit

public struct PDFDataBlockDocumentRenderer<
    ImageRenderer: PDFImageRenderer,
    RectLayout: RectSeriesLayout & PageLayout
>: PDFDocumentRenderer {
    public typealias Document = DataBlockDocument

    public let documentSize: any PDFDocumentSize
    public let rendererFactory: any PDFRendererFactory
    public let imageRenderer: ImageRenderer
    public let blockLayout: (CGRect) -> RectLayout

    public init(
        documentSize: any PDFDocumentSize,
        rendererFactory: any PDFRendererFactory,
        imageRenderer: ImageRenderer,
        blockLayout: @escaping (CGRect) -> RectLayout
    ) {
        self.documentSize = documentSize
        self.rendererFactory = rendererFactory
        self.imageRenderer = imageRenderer
        self.blockLayout = blockLayout
    }

    public func render(document: DataBlockDocument) throws -> PDFDocument {
        let renderer = rendererFactory.makeRenderer()
        let data = renderer.pdfData { context in
            let drawer = PDFDocumentDrawerHelper(
                context: context,
                documentSize: documentSize,
                headerGenerator: document.headerGenerator,
                labelRenderer: PDFLabelRenderer(),
                pageLayout: blockLayout
            )
            drawer.startNextPage()
            for content in document.content {
                switch content {
                case let .title(label):
                    drawer.draw(label: label)
                case let .images(imageData):
                    drawer.draw(images: imageData, imageRenderer: imageRenderer, rectSeriesLayout: blockLayout)
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

private final class PDFDocumentDrawerHelper<Layout: PageLayout> {
    let context: UIGraphicsPDFRendererContext
    private let headerGenerator: any DataBlockHeaderGenerator
    private let pageLayout: (CGRect) -> Layout
    private let documentSize: any PDFDocumentSize
    private let labelRenderer: PDFLabelRenderer
    private var currentVerticalOffset = 0.0
    private var currentImageNumberOnPage = 0
    private var currentPage = 0

    init(
        context: UIGraphicsPDFRendererContext,
        documentSize: any PDFDocumentSize,
        headerGenerator: any DataBlockHeaderGenerator,
        labelRenderer: PDFLabelRenderer,
        pageLayout: @escaping (CGRect) -> Layout
    ) {
        self.context = context
        self.documentSize = documentSize
        self.headerGenerator = headerGenerator
        self.labelRenderer = labelRenderer
        self.pageLayout = pageLayout
    }

    private var currentPageBoundsWithMargin: CGRect {
        context.pdfContextBounds.inset(by: documentSize.pointMargins)
    }

    func draw(label: DataBlockLabel) {
        func attemptToDrawLabel() throws {
            let currentLayoutEngine = pageLayout(currentPageBoundsWithMargin)
            let (attributedString, rect) = renderedLabel(for: label)
            if currentLayoutEngine.isFullyWithinBounds(rect: rect) {
                attributedString.draw(in: rect)
                currentVerticalOffset += label.padding.top
                currentVerticalOffset += rect.height
            } else {
                throw NoPlaceToDraw()
            }
        }

        do {
            try attemptToDrawLabel()
        } catch {
            startNextPage()
            try? attemptToDrawLabel()
        }
    }

    struct NoPlaceToDraw: Error {}

    func draw(
        images: [Data],
        imageRenderer: some PDFImageRenderer,
        rectSeriesLayout: (CGRect) -> some RectSeriesLayout
    ) {
        var currentImageNumberOnPage: UInt = 0
        var newOffset = currentVerticalOffset

        for imageData in images {
            defer { currentImageNumberOnPage += 1 }

            /// Gets the next location and attempts to draw the image there.
            /// - Throws `NoPlaceToDraw` if we can't get a rect for that location.
            func attemptToDrawNextImage() throws {
                let margins = documentSize.pointMargins
                let currentInsets = UIEdgeInsets(
                    top: currentVerticalOffset,
                    left: margins.left,
                    bottom: margins.bottom,
                    right: margins.right
                )
                let currentLayoutEngine = rectSeriesLayout(context.pdfContextBounds.inset(by: currentInsets))
                guard let rect = currentLayoutEngine.rect(atIndex: currentImageNumberOnPage) else {
                    throw NoPlaceToDraw()
                }
                let image = imageRenderer.makeImage(fromData: imageData, size: rect.size)
                image?.draw(in: rect)
                newOffset = rect.maxY + currentLayoutEngine.spacing
            }

            do {
                try attemptToDrawNextImage()
            } catch {
                // start a new page and draw from there
                startNextPage()
                currentImageNumberOnPage = 0

                // if this fails, we can't draw the image, even on the next page.
                // there probably just isn't enough space on the page, so ignore.
                // FIXME: should this throw? probably
                try? attemptToDrawNextImage()
            }
        }
        currentVerticalOffset = newOffset
    }

    func startNextPage() {
        context.beginPage()
        currentPage += 1
        currentVerticalOffset = 0.0
        currentVerticalOffset += documentSize.pointMargins.top

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

    private func renderedHeaderLabel(text: String, position: PDFLabelHeaderPosition) -> (NSAttributedString, CGRect) {
        let headerBottomSpacing = 8.0
        let attributedString = labelRenderer.makeAttributedTextForHeader(text: text, position: position)
        let width = currentPageBoundsWithMargin.width / 2
        let boundingRect = attributedString.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        )
        let textRect = CGRect(
            x: position.xPosition(width: width, margins: documentSize.pointMargins),
            y: documentSize.pointMargins.top,
            width: width,
            height: boundingRect.height + headerBottomSpacing
        )
        return (attributedString, textRect)
    }

    private func renderedLabel(for label: DataBlockLabel) -> (NSAttributedString, CGRect) {
        let attributedText = labelRenderer.makeAttributedTextForLabel(label)
        let width = currentPageBoundsWithMargin.width - label.padding.horizontalTotal
        let boundingRect = attributedText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        )
        let textRect = CGRect(
            x: documentSize.pointMargins.left + label.padding.left,
            y: currentVerticalOffset + label.padding.top,
            width: width,
            height: boundingRect.height + label.padding.bottom
        )
        return (attributedText, textRect)
    }
}
