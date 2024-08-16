import Foundation
import SwiftUI

struct NoListBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(EmptyView())
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
    }
}

extension View {
    func noListBackground() -> some View {
        modifier(NoListBackground())
    }
}
