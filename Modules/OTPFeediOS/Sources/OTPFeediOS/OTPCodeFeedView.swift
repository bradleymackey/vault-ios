import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

public struct OTPCodeFeedView<Store: OTPCodeStoreReader, TOTPView: TOTPViewGenerator>: View {
    @ObservedObject public var viewModel: FeedViewModel<Store>
    public var totpGenerator: TOTPView

    public init(viewModel: FeedViewModel<Store>, totpGenerator: TOTPView) {
        _viewModel = ObservedObject(initialValue: viewModel)
        self.totpGenerator = totpGenerator
    }

    public var body: some View {
        List {
            ForEach(viewModel.codes) { storedCode in
                switch storedCode.code.type {
                case let .totp(period):
                    totpGenerator.makeTOTPView(period: period, code: storedCode.code)
                case .hotp:
                    Text("unsupported")
                }
            }
        }
        .task {
            await viewModel.reloadData()
        }
    }
}

struct OTPCodeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        OTPCodeFeedView(
            viewModel: .init(store: MockCodeStore()),
            totpGenerator: LiveTOTPViewGenerator(
                clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
                timer: LiveIntervalTimer()
            )
        )
    }
}
