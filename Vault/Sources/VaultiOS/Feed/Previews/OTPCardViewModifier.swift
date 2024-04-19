import Foundation
import SwiftUI

public struct OTPCardViewModifier: ViewModifier {
    public enum Context {
        case primary
        case secondary
    }

    var context: Context
    public init(context: Context = .secondary) {
        self.context = context
    }

    public func body(content: Content) -> some View {
        content
            .padding(8)
            .background(backgroundColor)
            .clipShape(clipShape())
            .contentShape([.dragPreview], clipShape())
    }

    private var backgroundColor: Color {
        switch context {
        case .primary: Color(UIColor.systemBackground)
        case .secondary: Color(UIColor.secondarySystemBackground)
        }
    }

    private func clipShape() -> some Shape {
        RoundedRectangle(cornerRadius: 8)
    }
}

struct OTPCardViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        Text("Testing")
            .modifier(OTPCardViewModifier())
    }
}
