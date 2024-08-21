import Foundation
import SwiftUI

struct FormRow<Content: View>: View {
    var image: Image
    var color: Color
    var style: Style
    var content: () -> Content

    private let prominentIconSize: Double = 28

    enum Style {
        case prominent
        case standard
    }

    init(image: Image, color: Color, style: Style = .prominent, @ViewBuilder content: @escaping () -> Content) {
        self.image = image
        self.color = color
        self.style = style
        self.content = content
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            switch style {
            case .prominent:
                prominentIcon
            case .standard:
                standardIcon
            }
            content()
        }
    }

    private var prominentIcon: some View {
        ZStack {
            color
            image
                .font(.system(size: prominentIconSize / 2.5))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(width: prominentIconSize, height: prominentIconSize)
        .foregroundStyle(.white)
    }

    private var standardIcon: some View {
        image
            .frame(width: prominentIconSize, height: prominentIconSize)
            .foregroundStyle(color)
    }
}
