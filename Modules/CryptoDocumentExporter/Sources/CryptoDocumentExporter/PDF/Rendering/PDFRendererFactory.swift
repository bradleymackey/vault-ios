import UIKit

/// Creates a rendering context where PDFs will be drawn onto.
public protocol PDFRendererFactory {
    func makeRenderer() -> UIGraphicsPDFRenderer
}
