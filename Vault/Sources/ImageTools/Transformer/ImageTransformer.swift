import Foundation
import UIKit

/// @mockable
public protocol ImageTransformer {
    func tranform(image: UIImage) -> UIImage
}
