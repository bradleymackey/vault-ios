import CryptoEngine
import OTPCore
import OTPFeed
import SwiftUI

struct OTPCodeFeedView<Store: OTPCodeStoreReader>: View {
    @ObservedObject var viewModel: FeedViewModel<Store>
    let clock: EpochClock
    let timer: LiveIntervalTimer

    var body: some View {
        List {
            ForEach(viewModel.codes) { storedCode in
                switch storedCode.code.type {
                case let .totp(period):
                    makeTOTPView(period: period, code: storedCode.code)
                case .hotp:
                    Text("unsupported")
                }
            }
        }
        .task {
            await viewModel.reloadData()
        }
    }

    private func makeTOTPView(period: UInt32, code: OTPAuthCode) -> some View {
        let hotpGenerator = code.hotpGenerator()
        let totpGenerator = TOTPGenerator(generator: hotpGenerator, timeInterval: UInt64(period))
        let mapper = TOTPCodeMapper(period: Double(period), generator: totpGenerator, clock: clock, interval: timer)
        let (timer, renderer) = mapper.create()
        return OTPCodePreviewView(
            accountName: code.accountName,
            issuer: code.issuer,
            textView: .init(viewModel: .init(renderer: renderer), codeSpacing: 10.0),
            timerView: .init(viewModel: .init(updater: timer, clock: clock)),
            previewViewModel: .init(renderer: renderer)
        )
    }
}

struct OTPCodeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        OTPCodeFeedView(
            viewModel: .init(store: MockCodeStore()),
            clock: EpochClock(makeCurrentTime: { Date.now.timeIntervalSince1970 }),
            timer: LiveIntervalTimer()
        )
    }
}
