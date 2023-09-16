import Foundation
import SwiftUI

public struct FormRow: View {
    public var title: String
    public var image: Image
    public var color: Color

    public init(title: String, image: Image, color: Color) {
        self.title = title
        self.image = image
        self.color = color
    }

    public var body: some View {
        Label {
            Text(title)
        } icon: {
            RowIcon(icon: image, color: color)
                .foregroundColor(.white)
        }
    }
}
