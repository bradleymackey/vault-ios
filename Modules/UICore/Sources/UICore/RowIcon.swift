import SwiftUI

/// An icon for a row with background and rounding.
public struct RowIcon: View {
    public var icon: Image
    public var color: Color

    public init(icon: Image, color: Color) {
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        icon
            .padding(6)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
