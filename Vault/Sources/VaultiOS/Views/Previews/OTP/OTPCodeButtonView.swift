import SwiftUI
import VaultFeed

@MainActor
struct OTPCodeButtonView: View {
    var viewModel: OTPCodeIncrementerViewModel

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        AsyncButton {
            try await viewModel.incrementCounter()
        } label: {
            OTPCodeButtonIcon(isError: viewModel.incrementError != nil)
                .font(.system(size: 24, weight: isDisabled ? .light : .bold))
        }
        .foregroundStyle(viewModel.incrementError != nil ? .red : .accentColor)
        .disabled(isDisabled)
        .animation(.easeOut, value: isDisabled)
    }

    var isDisabled: Bool {
        !viewModel.isButtonEnabled || !isEnabled
    }
}
