import Foundation
import SwiftUI

public struct FormRow<Content: View>: View {
    public var image: Image
    public var color: Color
    public var content: () -> Content

    public init(image: Image, color: Color, @ViewBuilder content: @escaping () -> Content) {
        self.image = image
        self.color = color
        self.content = content
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            RowIcon(icon: image, color: color)
                .foregroundColor(.white)
            content()
        }
    }
}
