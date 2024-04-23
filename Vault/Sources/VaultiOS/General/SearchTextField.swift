import Foundation
import SwiftUI

struct SearchTextField: View {
    var title: String
    @Binding var text: String

    @FocusState private var isFocused: Bool
    let radius = 8.0

    var body: some View {
        HStack(spacing: 8) {
            TextField(title, text: $text)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .focused($isFocused)
                .padding(radius)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: radius))

            if text != "" {
                cancelButton
            }
        }
        .animation(.snappy, value: text)
    }

    private var cancelButton: some View {
        Button {
            text = ""
            isFocused = false
        } label: {
            Text("Cancel")
                .foregroundStyle(.primary, .secondary)
        }
    }

    private var backgroundColor: Color {
        Color(UIColor.secondarySystemBackground)
    }
}
