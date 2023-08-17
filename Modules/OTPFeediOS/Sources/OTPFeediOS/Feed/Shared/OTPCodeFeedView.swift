import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

public struct OTPCodeFeedView<
    Store: OTPCodeStore,
    ViewGenerator: OTPViewGenerator
>: View where
    ViewGenerator.Code == GenericOTPAuthCode
{
    @ObservedObject public var viewModel: FeedViewModel<Store>
    public var viewGenerator: ViewGenerator
    @Binding public var isEditing: Bool
    public var gridSpacing: Double

    public init(
        viewModel: FeedViewModel<Store>,
        viewGenerator: ViewGenerator,
        isEditing: Binding<Bool>,
        gridSpacing: Double = 8
    ) {
        _viewModel = ObservedObject(initialValue: viewModel)
        self.viewGenerator = viewGenerator
        _isEditing = Binding(projectedValue: isEditing)
        self.gridSpacing = gridSpacing
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, content: {
                ForEach(viewModel.codes) { code in
                    viewGenerator.makeOTPView(id: code.id, code: code.code, isEditing: isEditing)
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
            viewModel: .init(store: InMemoryCodeStore(codes: [])),
            viewGenerator: GenericGenerator(),
            isEditing: .constant(false)
        )
    }

    struct GenericGenerator: OTPViewGenerator {
        func makeOTPView(id _: UUID, code _: GenericOTPAuthCode, isEditing _: Bool) -> some View {
            Text("Code")
        }
    }
}
