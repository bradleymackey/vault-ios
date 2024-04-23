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
        textView.isScrollEnabled = true
        return textView
    }

    func updateUIView(_ uiView: SelectableTextView, context _: Context) {
        uiView.text = text
        uiView.font = font
        uiView.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: SelectableTextView, context _: Context) -> CGSize? {
        let size = CGSize(
            width: proposal.width ?? .greatestFiniteMagnitude,
            height: proposal.height ?? .greatestFiniteMagnitude
        )
        return uiView.sizeThatFits(size)
    }
}
