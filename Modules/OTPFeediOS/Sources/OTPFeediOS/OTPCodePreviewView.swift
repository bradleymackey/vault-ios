import Combine
import OTPCore
import OTPFeed
import SwiftUI

public struct OTPCodePreviewView<Updater: CodeTimerUpdater>: View {
    var accountName: String
    var issuer: String?
    var textView: CodeTextView
    var timerView: CodeTimerHorizontalBarView<Updater>
    @ObservedObject var previewViewModel: CodePreviewViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        VStack(alignment: .leading, spacing: 4) {
            textView
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.bold)
            timerSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var timerSection: some View {
        ZStack(alignment: .leading) {
            activeTimerView
                .frame(height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            switch previewViewModel.code {
            case let .error(err):
                LoadingBarLabel(text: err.userTitle)
            case .noMoreCodes:
                LoadingBarLabel(text: "No more codes")
            case .visible, .notReady:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var activeTimerView: some View {
        switch previewViewModel.code {
        case .visible:
            timerView
        case .error:
            Rectangle().fill(Color.red)
        case .noMoreCodes, .notReady:
            Rectangle().fill(Color.gray)
        }
    }

    private struct LoadingBarLabel: View {
        var text: String
        var body: some View {
            Text(text)
                .textCase(.uppercase)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
        }
    }
}

struct OTPCodePreviewView_Previews: PreviewProvider {
    private static let codeRenderer = OTPCodeRendererMock()
    private static let errorRenderer = OTPCodeRendererMock()
    private static let noMoreCodesRenderer = OTPCodeRendererMock()

    static var previews: some View {
        VStack(spacing: 40) {
            makePreview(issuer: "Working Example", renderer: codeRenderer)
                .onAppear {
                    codeRenderer.subject.send("123456")
                }

            makePreview(issuer: nil, renderer: codeRenderer)

            makePreview(issuer: "Code Error Example", renderer: errorRenderer)
                .onAppear {
                    errorRenderer.subject.send(completion: .failure(NSError(domain: "sdf", code: 1)))
                }

            makePreview(issuer: "No More Codes Example", renderer: noMoreCodesRenderer)
                .onAppear {
                    noMoreCodesRenderer.subject.send(completion: .finished)
                }
        }
        .onAppear {
            updater.subject.send(.init(startTime: 15, endTime: 100))
        }
    }

    static func makePreview(issuer: String?, renderer: OTPCodeRendererMock) -> some View {
        OTPCodePreviewView(
            accountName: "test@example.com",
            issuer: issuer,
            textView: CodeTextView(
                viewModel: .init(renderer: renderer),
                codeSpacing: 10
            ),
            timerView: CodeTimerHorizontalBarView(
                viewModel: .init(updater: updater, clock: clock),
                color: .blue
            ),
            previewViewModel: .init(renderer: renderer)
        )
        .frame(width: 250, height: 100)
    }

    static func viewModel(clock: EpochClock) -> CodeTimerViewModel<MockCodeTimerUpdater> {
        CodeTimerViewModel(updater: updater, clock: clock)
    }

    private static let updater: MockCodeTimerUpdater = .init()

    static let clock = EpochClock { 20 }
}
