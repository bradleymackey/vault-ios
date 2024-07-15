import Foundation

public struct VaultItemColor: Equatable, Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

extension VaultItemColor {
    /// A sensible placeholder color to use when there's
    public static var `default`: VaultItemColor {
        .gray
    }

    public static var gray: VaultItemColor {
        VaultItemColor(red: 0.5, green: 0.5, blue: 0.5)
    }

    public static var black: VaultItemColor {
        VaultItemColor(red: 0, green: 0, blue: 0)
    }

    public static var white: VaultItemColor {
        VaultItemColor(red: 1, green: 1, blue: 1)
    }

    public static func random() -> VaultItemColor {
        VaultItemColor(
            red: Double.random(in: 0 ... 1),
            green: Double.random(in: 0 ... 1),
            blue: Double.random(in: 0 ... 1)
        )
    }
}
