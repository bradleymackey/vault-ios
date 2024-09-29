import Foundation
import PDFKit
import UIKit

/// A stubable `UIGraphicsPDFRenderer` that can return custom data.
class UIGraphicsPDFRendererStub: UIGraphicsPDFRenderer {
    var pdfDataValue = Data()
    override func pdfData(actions _: (UIGraphicsPDFRendererContext) -> Void) -> Data {
        pdfDataValue
    }
}
