import UIKit

public protocol PDFImageRenderer {
    func makeImage(fromData data: Data, size: CGSize) -> UIImage?
}
