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
        List {
            ForEach(viewModel.codePairs) { codePair in
                HStack(alignment: .top) {
                    ForEach(codePair.codes) { code in
                        codeView(storedCode: code)
                    }
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(.init(
                top: gridSpacing / 2,
                leading: gridSpacing,
                bottom: gridSpacing / 2,
                trailing: gridSpacing
            ))
        }
        .listStyle(.plain)
        .task {
            await viewModel.reloadData()
        }
    }

    @ViewBuilder
    private func codeView(storedCode: StoredOTPCode) -> some View {
        switch storedCode.code.type {
        case let .totp(period):
            totpGenerator.makeTOTPView(period: period, code: storedCode)
        case let .hotp(counter):
            hotpGenerator.makeHOTPView(counter: counter, code: storedCode)
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 400), spacing: gridSpacing, alignment: .top)]
    }
}

struct OTPCodeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        OTPCodeFeedView(
            viewModel: .init(store: CodeStoreFake()),
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
        HOTPPreviewViewGenerator(timer: LiveIntervalTimer(), hideCodes: false)
    }
}
