import Foundation

public struct VaultItemColor: Equatable, Hashable {
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
    public static var `default`: VaultItemColor {
        VaultItemColor(red: 0, green: 0, blue: 0)
    }
}
