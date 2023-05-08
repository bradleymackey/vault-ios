import OTPCore
import OTPFeed
import SwiftUI

struct CodeButtonView<Timer: IntervalTimer>: View {
    @ObservedObject var viewModel: CodeIncrementerViewModel<Timer>

    var body: some View {
        Button {
            viewModel.incrementCounter()
        } label: {
            CodeButtonIcon()
        }
        .foregroundColor(.accentColor)
    }
}
