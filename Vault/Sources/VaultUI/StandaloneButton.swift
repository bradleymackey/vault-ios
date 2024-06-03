import Foundation
import SwiftUI

public struct StandaloneButton<Content: View>: View {
    public var action: () async -> Void
    public var content: () -> Content

    @State private var currentTask: Task<Void, Never>?

    public init(action: @escaping () async -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }

    public var body: some View {
        Button {
            currentTask?.cancel()
            currentTask = Task {
                await action()
            }
        } label: {
            content()
                .font(.callout)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
