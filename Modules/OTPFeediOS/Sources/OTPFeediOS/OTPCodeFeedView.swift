import OTPFeed
import SwiftUI

struct OTPCodeFeedView<Store: OTPCodeStoreReader>: View {
    @ObservedObject var viewModel: FeedViewModel<Store>

    var body: some View {
        List {
            ForEach(viewModel.codes) { code in
                Text(code.code.accountName)
            }
        }
        .task {
            await viewModel.reloadData()
        }
    }
}

struct OTPCodeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        OTPCodeFeedView(viewModel: .init(store: MockCodeStore()))
    }
}
