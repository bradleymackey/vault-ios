import Foundation
import SwiftUI
import UIKit

struct SelectableText: UIViewRepresentable {
    typealias UIViewType = SelectableTextView

    private var text: String
    private var font: UIFont

    init(_ text: String, font: UIFont) {
        self.text = text
        self.font = font
    }

    func makeUIView(context _: Context) -> SelectableTextView {
        let textView = SelectableTextView(frame: .zero)
        textView.delegate = textView
        textView.text = text
        textView.font = font
        textView.isEditable = false
        textView.isSelectable = true
        return textView
    }

    func updateUIView(_ uiView: SelectableTextView, context _: Context) {
        uiView.text = text
        uiView.font = font
    }
}
