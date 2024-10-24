import Foundation
import SwiftUI

struct VaultCardModifier: ViewModifier {
    struct Context {
        enum Style {
            case prominent
            case secondary
        }

        var style: Style
        var border: Color
    }

    var context: Context
    init(context: Context) {
        self.context = context
    }

    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(backgroundColor)
            .clipShape(clipShape())
            .overlay(
                clipShape()
                    .stroke(borderColor, lineWidth: 2)
            )
            .contentShape([.dragPreview], clipShape())
    }

    private var backgroundColor: Color {
        switch context.style {
        case .prominent: Color.blue
        case .secondary: Color(UIColor.secondarySystemBackground)
        }
    }

    private var borderColor: Color {
        switch context.style {
        case .prominent: Color.clear
        case .secondary: context.border.opacity(0.3)
        }
    }

    private func clipShape() -> some Shape {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }
}

#Preview {
    Text("Testing")
        .modifier(VaultCardModifier(context: .init(style: .secondary, border: .blue)))
}
