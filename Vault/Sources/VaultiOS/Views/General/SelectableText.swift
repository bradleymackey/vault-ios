import Combine
import Foundation
import SwiftUI
import UIKit

struct SelectableText: UIViewRepresentable {
    typealias UIViewType = SelectableTextView

    enum FontStyle {
        case normal, monospace
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var text: String
    private var fontStyle: FontStyle
    private var textStyle: UIFont.TextStyle

    init(_ text: String, fontStyle: FontStyle, textStyle: UIFont.TextStyle) {
        self.text = text
        self.fontStyle = fontStyle
        self.textStyle = textStyle
    }

    func makeUIView(context: Context) -> SelectableTextView {
        let textView = SelectableTextView(frame: .zero)
        textView.delegate = textView
        textView.text = text
        textView.adjustsFontForContentSizeCategory = true
        textView.font = fontStyle.makeFont(size: textStyle, dynamicTypeSize: context.environment.dynamicTypeSize)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        return textView
    }

    func updateUIView(_ uiView: SelectableTextView, context: Context) {
        uiView.text = text
        uiView.font = fontStyle.makeFont(size: textStyle, dynamicTypeSize: context.environment.dynamicTypeSize)
        uiView.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: SelectableTextView, context _: Context) -> CGSize? {
        let size = CGSize(
            width: proposal.width ?? .greatestFiniteMagnitude,
            height: proposal.height ?? .greatestFiniteMagnitude,
        )
        return uiView.sizeThatFits(size)
    }
}

extension SelectableText.FontStyle {
    fileprivate var uifont: UIFont {
        switch self {
        case .normal: .systemFont(ofSize: 16)
        case .monospace: .monospacedSystemFont(ofSize: 16, weight: .regular)
        }
    }

    func makeFont(size: UIFont.TextStyle, dynamicTypeSize: DynamicTypeSize) -> UIFont {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: dynamicTypeSize.contentSizeCategory)
        return UIFontMetrics(forTextStyle: size).scaledFont(for: uifont, compatibleWith: traitCollection)
    }
}
