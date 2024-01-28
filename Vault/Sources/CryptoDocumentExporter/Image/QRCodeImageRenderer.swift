import Foundation
import UIKit

/// Image renderer for QR codes.
public struct QRCodeImageRenderer: PDFImageRenderer {
    public init() {}

    public func makeImage(fromData data: Data, size: CGSize) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        let resizer = UIImageResizer(mode: .noSmoothing)
        return resizer.resize(image: image, to: size)
    }
}
