import Combine
import Foundation
import SwiftUI
import UIKit

struct SelectableText: UIViewRepresentable {
    typealias UIViewType = SelectableTextView

    enum TextStyle {
        case normal, monospace
    }

    @State private var currentFontSize: Double

    private var text: String
    private var textStyle: TextStyle
    private var dynamicTypeSize: UIFont.TextStyle

    init(_ text: String, textStyle: TextStyle, dynamicTypeSize: UIFont.TextStyle) {
        self.text = text
        self.textStyle = textStyle
        self.dynamicTypeSize = dynamicTypeSize
        _currentFontSize = State(initialValue: dynamicTypeSize.currentSize)
    }

    private var currentTextFont: UIFont {
        textStyle.uifont.withSize(currentFontSize)
    }

    func makeUIView(context _: Context) -> SelectableTextView {
        let textView = SelectableTextView(frame: .zero)
        textView.delegate = textView
        textView.text = text
        textView.adjustsFontForContentSizeCategory = true
        textView.font = currentTextFont
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        return textView
    }

    func updateUIView(_ uiView: SelectableTextView, context _: Context) {
        uiView.text = text
        uiView.font = currentTextFont
        uiView.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: SelectableTextView, context _: Context) -> CGSize? {
        let size = CGSize(
            width: proposal.width ?? .greatestFiniteMagnitude,
            height: proposal.height ?? .greatestFiniteMagnitude
        )
        return uiView.sizeThatFits(size)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(notificationCenter: .default, dynamicTypeSize: dynamicTypeSize, currentFontSize: $currentFontSize)
    }

    final class Coordinator {
        @Binding var currentFontSize: Double

        private var contentSizeListener: AnyCancellable?
        private let dynamicTypeSize: UIFont.TextStyle
        init(
            notificationCenter: NotificationCenter,
            dynamicTypeSize: UIFont.TextStyle,
            currentFontSize: Binding<Double>
        ) {
            _currentFontSize = currentFontSize
            self.dynamicTypeSize = dynamicTypeSize
            contentSizeListener = notificationCenter.publisher(for: UIContentSizeCategory.didChangeNotification)
                .sink { [weak self] _ in
                    self?.currentFontSize = dynamicTypeSize.currentSize
                }
        }
    }
}

extension SelectableText.TextStyle {
    fileprivate var uifont: UIFont {
        // The size here is just a placeholder, it should be changed based on the current dynamic type size.
        switch self {
        case .normal: .systemFont(ofSize: 1)
        case .monospace: .monospacedSystemFont(ofSize: 1, weight: .regular)
        }
    }
}

extension UIFont.TextStyle {
    fileprivate var currentSize: Double {
        UIFont.preferredFont(forTextStyle: self).pointSize
    }
}
