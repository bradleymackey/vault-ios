import Foundation
import SwiftUI

public struct StandaloneButton<Content: View>: View {
    public var action: () -> Void
    public var content: () -> Content

    public init(action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }

    public var body: some View {
        Button {
            action()
        } label: {
            content()
                .font(.callout)
                .foregroundStyle(.white)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
