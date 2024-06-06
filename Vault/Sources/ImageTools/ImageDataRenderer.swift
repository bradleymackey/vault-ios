import UIKit

/// @mockable
public protocol ImageDataRenderer {
    /// Makes an image from the provided data.
    /// The way this transformation happens is down to each individual renderer.
    func makeImage(fromData data: Data, size: CGSize?) -> UIImage?
}
