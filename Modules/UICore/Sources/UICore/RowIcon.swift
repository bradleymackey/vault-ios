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
            .imageScale(.medium)
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .aspectRatio(1.0, contentMode: .fill)
                    .foregroundColor(color)
            )
    }
}
