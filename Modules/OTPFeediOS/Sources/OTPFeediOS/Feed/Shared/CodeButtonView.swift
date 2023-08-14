import OTPCore
import OTPFeed
import SwiftUI

struct CodeButtonView: View {
    @ObservedObject var viewModel: CodeIncrementerViewModel

    var body: some View {
        Button {
            viewModel.incrementCounter()
        } label: {
            CodeButtonIcon()
        }
        .foregroundColor(.accentColor)
        .disabled(!viewModel.isButtonEnabled)
    }
}
