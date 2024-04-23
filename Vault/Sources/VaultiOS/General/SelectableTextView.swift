import Foundation
import SwiftUI
import UIKit

final class SelectableTextView: UITextView {
    // change the cursor to have zero size
    override func caretRect(for _: UITextPosition) -> CGRect {
        .zero
    }
}

extension SelectableTextView: UITextViewDelegate {}
