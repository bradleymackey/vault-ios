import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

public struct OTPCodeFeedView<
    Store: OTPCodeStoreReader,
    TOTPView: TOTPViewGenerator,
    HOTPView: HOTPViewGenerator
>: View {
    @ObservedObject public var viewModel: FeedViewModel<Store>
    public var totpGenerator: TOTPView
    public var hotpGenerator: HOTPView
    public var gridSpacing: Double

    public init(
        viewModel: FeedViewModel<Store>,
        totpGenerator: TOTPView,
        hotpGenerator: HOTPView,
        gridSpacing: Double = 8
    ) {
        _viewModel = ObservedObject(initialValue: viewModel)
        self.totpGenerator = totpGenerator
        self.hotpGenerator = hotpGenerator
        self.gridSpacing = gridSpacing
    }

    public var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(viewModel.codes) { storedCode in
                    switch storedCode.code.type {
                    case let .totp(period):
                        totpGenerator.makeTOTPView(period: period, code: storedCode.code)
                            .modifier(CardModifier(innerPadding: 8))
                    case let .hotp(counter):
                        hotpGenerator.makeHOTPView(counter: counter, code: storedCode.code)
                            .modifier(CardModifier(innerPadding: 8))
                    }
                }
            }
        }
        .task {
            await viewModel.reloadData()
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 400))]
    }
}

struct CardModifier: ViewModifier {
    var innerPadding: Double

    func body(content: Content) -> some View {
        content
            .padding(innerPadding)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct OTPCodeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        OTPCodeFeedView(
            viewModel: .init(store: MockCodeStore()),
            totpGenerator: LiveTOTPViewGenerator(
                clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
                timer: LiveIntervalTimer()
            ),
            hotpGenerator: LiveHOTPViewGenerator()
        )
    }
}
