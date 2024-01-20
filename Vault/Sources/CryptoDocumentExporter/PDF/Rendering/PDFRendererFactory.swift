import Spyable
import UIKit

/// Creates a rendering context where PDFs will be drawn onto.
@Spyable
public protocol PDFRendererFactory {
    func makeRenderer() -> UIGraphicsPDFRenderer
}
