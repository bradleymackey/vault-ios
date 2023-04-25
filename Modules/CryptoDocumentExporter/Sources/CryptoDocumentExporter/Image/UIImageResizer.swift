import UIKit

public struct UIImageResizer {
    public enum Mode {
        case noSmoothing
    }

    public let mode: Mode

    public init(mode: Mode) {
        self.mode = mode
    }

    public func resize(image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            context.cgContext.interpolationQuality = .none
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
