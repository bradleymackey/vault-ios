import OTPCore
import OTPFeed
import SwiftUI

struct CodeButtonView: View {
    @ObservedObject var viewModel: CodeIncrementerViewModel

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button {
            viewModel.incrementCounter()
        } label: {
            CodeButtonIcon()
                .font(.system(size: 30, weight: isDisabled ? .light : .bold))
        }
        .foregroundColor(.accentColor)
        .disabled(isDisabled)
        .frame(width: 44, height: 44)
    }

    var isDisabled: Bool {
        !viewModel.isButtonEnabled || !isEnabled
    }
}
