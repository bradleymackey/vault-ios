import UIKit

/// @mockable
public protocol DataToImageRenderer {
    func makeImage(fromData data: Data, size: CGSize) -> UIImage?
}
