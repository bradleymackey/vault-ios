import Foundation
import SwiftUI

struct VaultCardModifier: ViewModifier {
    enum Context {
        case prominent
        case secondary
        case tertiary
    }

    var context: Context
    init(context: Context = .secondary) {
        self.context = context
    }

    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(backgroundColor)
            .clipShape(clipShape())
            .contentShape([.dragPreview], clipShape())
    }

    private var backgroundColor: Color {
        switch context {
        case .prominent: Color.blue
        case .secondary: Color(UIColor.secondarySystemBackground)
        case .tertiary: Color(UIColor.tertiarySystemBackground)
        }
    }

    private func clipShape() -> some Shape {
        RoundedRectangle(cornerRadius: 8)
    }
}

#Preview {
    Text("Testing")
        .modifier(VaultCardModifier())
}
