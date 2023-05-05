import Combine
import OTPCore
import OTPFeed
import SwiftUI

public struct OTPCodePreviewView: View {
    var accountName: String
    var issuer: String?
    var textView: CodeTextView
    var timerView: CodeTimerHorizontalBarView

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelSection
            codeSection
        }
        .frame(maxWidth: .infinity)
    }

    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let issuer {
                Text(issuer)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            Text(accountName)
                .font(.footnote)
                .foregroundColor(issuer != nil ? .secondary : .primary)
        }
    }

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            textView
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.bold)
            timerView
                .frame(height: 10)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct OTPCodePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        OTPCodePreviewView(
            accountName: "test@example.com",
            issuer: "Authority",
            textView: CodeTextView(
                viewModel: .init(renderer: codeRenderer),
                codeSpacing: 10
            ),
            timerView: CodeTimerHorizontalBarView(
                viewModel: .init(updater: updater, clock: clock),
                color: .blue
            )
        )
        .frame(width: 250, height: 100)
        .onAppear {
            codeRenderer.subject.send("123456")
            updater.subject.send(OTPTimerState(startTime: 15, endTime: 60))
        }
    }

    static func viewModel(clock: EpochClock) -> CodeTimerViewModel {
        CodeTimerViewModel(updater: updater, clock: clock)
    }

    private static let updater: MockCodeTimerUpdater = .init()

    static let clock = EpochClock { 20 }

    private static let codeRenderer = OTPCodeRendererMock()
}
