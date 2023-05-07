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
    public var contentPadding: EdgeInsets

    public init(
        viewModel: FeedViewModel<Store>,
        totpGenerator: TOTPView,
        hotpGenerator: HOTPView,
        gridSpacing: Double = 8,
        contentPadding: EdgeInsets = .init()
    ) {
        _viewModel = ObservedObject(initialValue: viewModel)
        self.totpGenerator = totpGenerator
        self.hotpGenerator = hotpGenerator
        self.gridSpacing = gridSpacing
        self.contentPadding = contentPadding
    }

    public var body: some View {
        ScrollView(.vertical) {
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
            .padding(contentPadding)
        }
        .task {
            await viewModel.reloadData()
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 400), spacing: gridSpacing, alignment: .bottom)]
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

    private static func totpGenerator() -> LiveTOTPPreviewViewGenerator {
        LiveTOTPPreviewViewGenerator(
            clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
            timer: LiveIntervalTimer(),
            hideCodes: false
        )
    }

    private static func hotpGenerator() -> LiveHOTPPreviewViewGenerator {
        LiveHOTPPreviewViewGenerator(hideCodes: false)
    }
}
