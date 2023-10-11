import SwiftUI
import VaultCore
import VaultFeed

@MainActor
struct CodeButtonView: View {
    var viewModel: CodeIncrementerViewModel

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button {
            viewModel.incrementCounter()
        } label: {
            CodeButtonIcon()
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
