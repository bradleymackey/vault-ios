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
}
