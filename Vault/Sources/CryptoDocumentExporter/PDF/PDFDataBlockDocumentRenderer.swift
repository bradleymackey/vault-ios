import Foundation
import PDFKit
import UIKit

public struct PDFDataBlockDocumentRenderer<
    ImageRenderer: PDFImageRenderer,
    RectLayout: RectSeriesLayout & PageLayout
>: PDFDocumentRenderer {
    public typealias Document = DataBlockDocument

    public let margins: UIEdgeInsets
    public let rendererFactory: any PDFRendererFactory
    public let imageRenderer: ImageRenderer
    public let blockLayout: (CGRect) -> RectLayout

    public init(
        margins: UIEdgeInsets,
        rendererFactory: any PDFRendererFactory,
        imageRenderer: ImageRenderer,
        blockLayout: @escaping (CGRect) -> RectLayout
    ) {
        self.margins = margins
        self.rendererFactory = rendererFactory
        self.imageRenderer = imageRenderer
        self.blockLayout = blockLayout
    }

    public func render(document: DataBlockDocument) throws -> PDFDocument {
        let renderer = rendererFactory.makeRenderer()
        let data = renderer.pdfData { context in
            let drawer = PDFDocumentDrawerHelper(
                context: context,
                margins: margins,
                headerGenerator: document.headerGenerator,
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
    private let margins: UIEdgeInsets
    private var currentVerticalOffset = 0.0
    private var currentImageNumberOnPage = 0
    private var currentPage = 0

    init(
        context: UIGraphicsPDFRendererContext,
        margins: UIEdgeInsets,
        headerGenerator: any DataBlockHeaderGenerator,
        pageLayout: @escaping (CGRect) -> Layout
    ) {
        self.context = context
        self.margins = margins
        self.headerGenerator = headerGenerator
        self.pageLayout = pageLayout
    }

    private var currentPageBoundsWithMargin: CGRect {
        context.pdfContextBounds.inset(by: margins)
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
        var currentImageNumberOnPage = 0
        var newOffset = currentVerticalOffset

        for imageData in images {
            defer { currentImageNumberOnPage += 1 }

            /// Gets the next location and attempts to draw the image there.
            /// - Throws `NoPlaceToDraw` if we can't get a rect for that location.
            func attemptToDrawNextImage() throws {
                if let location = getNextRectForImageOnPage(
                    imageNumberOnPage: currentImageNumberOnPage,
                    rectSeriesLayout: rectSeriesLayout
                ) {
                    let image = imageRenderer.makeImage(fromData: imageData, size: location.rect.size)
                    image?.draw(in: location.rect)
                    newOffset = location.maxYWithPadding
                } else {
                    throw NoPlaceToDraw()
                }
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
        currentVerticalOffset += margins.top

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
        let headerBottomSpacing = 8.0
        let labelFontSize = 9.0

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
        let width = currentPageBoundsWithMargin.width / 2
        let boundingRect = attributedString.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        )
        let textRect = CGRect(
            x: position.xPosition(width: width, margins: margins),
            y: margins.top,
            width: width,
            height: boundingRect.height + headerBottomSpacing
        )
        return (attributedString, textRect)
    }

    private struct TargetImageLocation {
        var rect: CGRect
        var gridSpacing: CGFloat

        var maxYWithPadding: CGFloat {
            rect.maxY + gridSpacing
        }
    }

    /// Returns the first rect that fits in the page bounds or `nil`.
    private func getNextRectForImageOnPage(
        imageNumberOnPage: Int,
        rectSeriesLayout: (CGRect) -> some RectSeriesLayout
    ) -> TargetImageLocation? {
        let currentInsets = UIEdgeInsets(top: currentVerticalOffset, left: 0, bottom: 0, right: 0)
        let currentLayoutEngine = rectSeriesLayout(currentPageBoundsWithMargin.inset(by: currentInsets))
        guard let rect = currentLayoutEngine.rect(atIndex: UInt(imageNumberOnPage)) else {
            return nil
        }
        return TargetImageLocation(rect: rect, gridSpacing: currentLayoutEngine.spacing)
    }

    private func renderedLabel(for label: DataBlockLabel) -> (NSAttributedString, CGRect) {
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
        let width = currentPageBoundsWithMargin.width - label.padding.horizontalTotal
        let boundingRect = attributedText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        )
        let textRect = CGRect(
            x: margins.left + label.padding.left,
            y: currentVerticalOffset + label.padding.top,
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

    func xPosition(width: CGFloat, margins: UIEdgeInsets) -> CGFloat {
        switch self {
        case .left: margins.left
        case .right: width + margins.left
        }
    }
}
