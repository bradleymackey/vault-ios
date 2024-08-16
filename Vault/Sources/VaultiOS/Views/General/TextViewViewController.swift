import Combine
import Foundation
import UIKit

final class TextViewViewController: UIViewController {
    private let font: UIFont
    private let textView: UITextView = {
        let view = UITextView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let textChangedSubject = PassthroughSubject<String, Never>()

    var cancellables = Set<AnyCancellable>()

    init(initialText: String, font: UIFont) {
        self.font = font
        super.init(nibName: nil, bundle: nil)

        textView.text = initialText
        textView.delegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
        ])
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.font = font
    }

    func textChangedPublisher() -> AnyPublisher<String, Never> {
        textChangedSubject.removeDuplicates().eraseToAnyPublisher()
    }
}

extension TextViewViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textChangedSubject.send(textView.text)
    }
}
