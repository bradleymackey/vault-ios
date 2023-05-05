import OTPFeed
import SwiftUI

struct CodeButtonView: View {
    @ObservedObject var viewModel: CodeIncrementerViewModel

    var body: some View {
        Button {
            viewModel.incrementCounter()
        } label: {
            Image(systemName: "arrow.clockwise")
        }
    }
}
