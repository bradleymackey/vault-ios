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
        LazyVGrid(columns: columns, alignment: .trailing, spacing: gridSpacing) {
            ForEach(viewModel.codes) { storedCode in
                switch storedCode.code.type {
                case let .totp(period):
                    totpGenerator.makeTOTPView(period: period, code: storedCode.code)
                case let .hotp(counter):
                    hotpGenerator.makeHOTPView(counter: counter, code: storedCode.code)
                }
            }
        }
        .task {
            await viewModel.reloadData()
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 400), spacing: gridSpacing, alignment: .top)]
    }
}

struct OTPCodeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        OTPCodeFeedView(
            viewModel: .init(store: MockCodeStore()),
            totpGenerator: totpGenerator(),
            hotpGenerator: hotpGenerator()
        )
    }

    private static func totpGenerator() -> TOTPPreviewViewGenerator {
        TOTPPreviewViewGenerator(
            clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
            timer: LiveIntervalTimer(),
            hideCodes: false
        )
    }

    private static func hotpGenerator() -> HOTPPreviewViewGenerator {
        HOTPPreviewViewGenerator(hideCodes: false)
    }
}
