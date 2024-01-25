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
    /// The current position where we are allowed to draw content.
    /// This will change as elements are drawn, as we are not allowed to override them.
    private var contentArea = PDFContentArea()
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

    func draw(label: DataBlockLabel) {
        func attemptToDrawLabel() throws {
            let currentLayoutEngine = pageLayout(contentArea.currentBounds)
            let attributedString = labelRenderer.makeAttributedTextForLabel(label)
            let width = contentArea.currentBounds.size.width - label.padding.horizontalTotal
            let boundingRect = attributedString.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                context: nil
            )
            let rect = CGRect(
                x: contentArea.currentBounds.minX + label.padding.left,
                y: contentArea.currentBounds.minY + label.padding.top,
                width: width,
                height: boundingRect.height + label.padding.bottom
            )
            if currentLayoutEngine.isFullyWithinBounds(rect: rect) {
                attributedString.draw(in: rect)
                contentArea.didDrawContent(at: rect)
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
        var currentLayoutEngine = rectSeriesLayout(contentArea.currentBounds)

        for imageData in images {
            defer { currentImageNumberOnPage += 1 }

            /// Gets the next location and attempts to draw the image there.
            /// - Throws `NoPlaceToDraw` if we can't get a rect for that location.
            func attemptToDrawNextImage() throws {
                guard let rect = currentLayoutEngine.rect(atIndex: currentImageNumberOnPage) else {
                    throw NoPlaceToDraw()
                }
                let image = imageRenderer.makeImage(fromData: imageData, size: rect.size)
                image?.draw(in: rect)
                contentArea.didDrawContent(at: rect)
            }

            do {
                try attemptToDrawNextImage()
            } catch {
                // start a new page and draw from there
                startNextPage()
                currentImageNumberOnPage = 0
                currentLayoutEngine = rectSeriesLayout(contentArea.currentBounds)

                // if this fails, we can't draw the image, even on the next page.
                // there probably just isn't enough space on the page, so ignore.
                // FIXME: should this throw? probably
                try? attemptToDrawNextImage()
            }
        }
    }

    /// Creates a new page and drawable content area.
    func startNextPage() {
        context.beginPage()
        currentPage += 1
        contentArea = PDFContentArea(fullSize: context.pdfContextBounds)
        contentArea.inset(by: documentSize.pointMargins)

        drawHeaderIfNeeded()
    }

    private func drawHeaderIfNeeded() {
        guard let header = headerGenerator.makeHeader(pageNumber: currentPage) else { return }
        for label in header.allHeaderLabels {
            let headerBottomSpacing = 8.0
            let attributedString = labelRenderer.makeAttributedTextForHeader(text: label.text, position: label.position)
            let width = contentArea.currentBounds.width / 2
            let boundingRect = attributedString.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                context: nil
            )
            let rect = CGRect(
                x: label.position.xPosition(width: width, margins: documentSize.pointMargins),
                y: documentSize.pointMargins.top,
                width: width,
                height: boundingRect.height + headerBottomSpacing
            )
            attributedString.draw(in: rect)
            contentArea.didDrawContent(at: rect)
        }
    }
}

// MARK: - Positioning

extension DataBlockHeader {
    fileprivate var allHeaderLabels: [(text: String, position: PDFLabelHeaderPosition)] {
        var labels = [(String, PDFLabelHeaderPosition)]()
        if let left {
            labels.append((left, .left))
        }
        if let right {
            labels.append((right, .right))
        }
        return labels
    }
}
