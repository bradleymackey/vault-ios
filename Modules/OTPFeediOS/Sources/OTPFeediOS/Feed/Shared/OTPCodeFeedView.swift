import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

public struct OTPCodeFeedView<
    Store: OTPCodeStoreReader,
    ViewGenerator: OTPViewGenerator
>: View where
    ViewGenerator.Code == GenericOTPAuthCode
{
    @ObservedObject public var viewModel: FeedViewModel<Store>
    public var viewGenerator: ViewGenerator
    public var gridSpacing: Double

    public init(
        viewModel: FeedViewModel<Store>,
        viewGenerator: ViewGenerator,
        gridSpacing: Double = 8
    ) {
        _viewModel = ObservedObject(initialValue: viewModel)
        self.viewGenerator = viewGenerator
        self.gridSpacing = gridSpacing
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, content: {
                ForEach(viewModel.codes) { code in
                    viewGenerator.makeOTPView(id: code.id, code: code.code)
                }
            })
            .padding()
        }
        .listStyle(.plain)
        .task {
            await viewModel.reloadData()
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: gridSpacing, alignment: .top)]
    }
}

struct OTPCodeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        OTPCodeFeedView(
            viewModel: .init(store: CodeStoreFake()),
            viewGenerator: GenericGenerator()
        )
    }

    struct GenericGenerator: OTPViewGenerator {
        func makeOTPView(id _: UUID, code _: GenericOTPAuthCode) -> some View {
            Text("Code")
        }
    }
}
