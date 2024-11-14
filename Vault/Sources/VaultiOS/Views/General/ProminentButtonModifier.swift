import Foundation
import SwiftUI

/// Makes a button prominent with a standard background color and border.
public struct ProminentButtonModifier: ViewModifier {
    var color: Color
    public init(color: Color = Color.accentColor) {
        self.color = color
    }

    public func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(.white)
            .buttonStyle(.borderless)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    Button {
        // noop
    } label: {
        Text("Hello")
    }
    .modifier(ProminentButtonModifier())
}
