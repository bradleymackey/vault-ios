import Foundation
import SwiftUI

struct SearchTextField: View {
    var title: String
    @Binding var text: String

    var body: some View {
        TextField(title, text: $text)
            .textFieldStyle(.plain)
            .submitLabel(.done)
            .padding(8)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var backgroundColor: Color {
        Color(UIColor.secondarySystemBackground)
    }
}
