import SwiftUI

/// An icon for a row with background and rounding.
public struct RowIcon: View {
    public var icon: Image
    public var color: Color
    public var size: Double

    public init(icon: Image, color: Color, size: Double = 32) {
        self.icon = icon
        self.color = color
        self.size = size
    }

    public var body: some View {
        ZStack {
            color
            icon
                .font(.system(size: size / 2))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(width: size, height: size)
    }
}

struct RowIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RowIcon(icon: Image(systemName: "square.and.arrow.up.on.square.fill"), color: .blue)
            RowIcon(icon: Image(systemName: "text.book.closed.fill"), color: .red)
            RowIcon(icon: Image(systemName: "ruler"), color: .green)
        }
        .previewLayout(.sizeThatFits)
        .environment(\.dynamicTypeSize, .accessibility3)
    }
}
