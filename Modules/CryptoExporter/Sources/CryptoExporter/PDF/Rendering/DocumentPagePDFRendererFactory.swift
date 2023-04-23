import UIKit

/// Produces renderers optimized for rendering a standard size document.
///
/// Contains information about the size of PDF to render and metadata that will be associated with the PDF.
public struct DocumentPagePDFRendererFactory: PDFRendererFactory {
    public var size: PDFDocumentSize
    public var documentTitle: String?
    public var applicationName: String?
    public var authorName: String?

    public init(size: PDFDocumentSize, applicationName: String? = nil, authorName: String? = nil, documentTitle: String? = nil) {
        self.size = size
        self.applicationName = applicationName
        self.authorName = authorName
        self.documentTitle = documentTitle
    }

    public func makeRenderer() -> UIGraphicsPDFRenderer {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetadata as [String: Any]

        return UIGraphicsPDFRenderer(bounds: pageRect(), format: format)
    }
}

// MARK: - Helpers

extension DocumentPagePDFRendererFactory {
    private func pageRect() -> CGRect {
        let (pageWidth, pageHeight) = size.pointSize()
        let size = CGSize(width: pageWidth, height: pageHeight)
        return CGRect(origin: .zero, size: size)
    }

    private var pdfMetadata: [CFString: String] {
        var metadata = [CFString: String]()
        metadata[kCGPDFContextCreator] = applicationName
        metadata[kCGPDFContextAuthor] = authorName
        metadata[kCGPDFContextTitle] = documentTitle
        return metadata
    }
}
