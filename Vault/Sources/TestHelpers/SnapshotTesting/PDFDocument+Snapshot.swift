#if canImport(UIKit)
import Foundation
import PDFKit
import SnapshotTesting

extension Snapshotting where Value == PDFDocument, Format == UIImage {
    /// Snapshots a PDF as an image, so we don't worry about metadata/non-visible aspects of the PDF.
    public static func pdf(page: Int = 1) -> Snapshotting {
        .init(
            pathExtension: "png",
            diffing: .image,
            snapshot: { pdfDocument in
                pdfDocument.asImage(page: page) ?? UIImage()
            },
        )
    }
}

extension PDFDocument {
    fileprivate func asImage(page: Int = 1) -> UIImage? {
        guard let data = dataRepresentation() else { return nil }
        let cfData = data as CFData
        guard let provider = CGDataProvider(data: cfData) else { return nil }
        guard let pdfDoc = CGPDFDocument(provider) else { return nil }
        guard let page = pdfDoc.page(at: page) else { return nil }

        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)

            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

            ctx.cgContext.drawPDFPage(page)
        }
    }
}

#endif
