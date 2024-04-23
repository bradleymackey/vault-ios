import Combine
import Foundation
import SwiftUI
import UIKit

/// A full-screen text editing view for longform content.
///
/// The reason for this view's existance is the bugs we've experienced with raw SwiftUI text editors.
/// It wraps a UIViewController under the hood, so we don't rely on SwiftUI for eventing at all.
struct TextEditingView: UIViewControllerRepresentable {
    typealias UIViewControllerType = TextViewViewController
    @Binding var text: String
    var font: UIFont

    func makeUIViewController(context _: Context) -> TextViewViewController {
        let viewController = TextViewViewController(initialText: text, font: font)
        viewController.textChangedPublisher()
            .sink { newValue in
                text = newValue
            }
            .store(in: &viewController.cancellables)
        return viewController
    }

    func updateUIViewController(_: TextViewViewController, context _: Context) {
        // empty
    }
}
