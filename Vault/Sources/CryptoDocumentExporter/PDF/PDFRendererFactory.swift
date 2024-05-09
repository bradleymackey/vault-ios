import UIKit

/// Creates a rendering context where PDFs will be drawn onto.
/// @mockable
public protocol PDFRendererFactory {
    var size: any PDFDocumentSize { get }
    func makeRenderer() -> UIGraphicsPDFRenderer
}

extension PDFRendererFactory {
    public func makeRenderer() -> UIGraphicsPDFRenderer {
        let size = size.pointSize()
        return UIGraphicsPDFRenderer(bounds: .init(origin: .zero, size: .init(width: size.width, height: size.height)))
    }
}
