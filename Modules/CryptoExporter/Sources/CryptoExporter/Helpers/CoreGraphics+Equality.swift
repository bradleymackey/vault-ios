import CoreGraphics

extension CGPoint {
    func isAlmostEqual(to point: CGPoint, tolerance: CGFloat = CGFloat.ulpOfOne.squareRoot()) -> Bool {
        x.isAlmostEqual(to: point.x, tolerance: tolerance) &&
            y.isAlmostEqual(to: point.y, tolerance: tolerance)
    }
}

extension CGSize {
    func isAlmostEqual(to size: CGSize, tolerance: CGFloat = CGFloat.ulpOfOne.squareRoot()) -> Bool {
        width.isAlmostEqual(to: size.width, tolerance: tolerance) &&
            height.isAlmostEqual(to: size.height, tolerance: tolerance)
    }
}

extension CGRect {
    func isAlmostEqual(to rect: CGRect, tolerance: CGFloat = CGFloat.ulpOfOne.squareRoot()) -> Bool {
        origin.isAlmostEqual(to: rect.origin, tolerance: tolerance) &&
            size.isAlmostEqual(to: rect.size, tolerance: tolerance)
    }
}
