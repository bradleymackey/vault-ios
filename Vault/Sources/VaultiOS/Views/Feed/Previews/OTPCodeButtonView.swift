import SwiftUI
import VaultFeed

@MainActor
struct OTPCodeButtonView: View {
    var viewModel: OTPCodeIncrementerViewModel

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button {
            viewModel.incrementCounter()
        } label: {
            OTPCodeButtonIcon()
                .font(.system(size: 22, weight: isDisabled ? .light : .bold))
        }
        .foregroundColor(.accentColor)
        .disabled(isDisabled)
        .frame(width: 33, height: 33)
    }

    var isDisabled: Bool {
        !viewModel.isButtonEnabled || !isEnabled
    }
}
