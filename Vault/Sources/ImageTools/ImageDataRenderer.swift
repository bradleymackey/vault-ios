import UIKit

/// @mockable
public protocol ImageDataRenderer {
    func makeImage(fromData data: Data, size: CGSize) -> UIImage?
}
