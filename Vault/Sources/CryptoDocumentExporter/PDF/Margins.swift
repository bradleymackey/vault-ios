import Foundation

public struct Margins {
    public var top: Double
    public var left: Double
    public var bottom: Double
    public var right: Double

    public init(top: Double, left: Double, bottom: Double, right: Double) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    public static func all(_ size: Double) -> Self {
        .init(top: size, left: size, bottom: size, right: size)
    }
}
