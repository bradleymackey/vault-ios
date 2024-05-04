import SwiftUI

/// An icon with a title and detail text below.
public struct SquareDetailIcon: View {
    public var image: Image
    public var color: Color
    public var title: String
    public var subtitle: String
    
    public init(image: Image, color: Color = .blue, title: String, subtitle: String) {
        self.image = image.renderingMode(.template)
        self.color = color
        self.title = title
        self.subtitle = subtitle
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 12) {
            ZStack {
                color
                image
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8.0))
            .frame(maxWidth: 100)
            
            labels
        }
    }
    
    private var labels: some View {
        VStack(alignment: .center) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SquareDetailIcon(
        image: Image(systemName: "person"),
        title: "Title",
        subtitle: "Subtitle"
    )
}
