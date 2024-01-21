import Spyable
import UIKit

@Spyable
public protocol PDFImageRenderer {
    func makeImage(fromData data: Data, size: CGSize) -> UIImage?
}
