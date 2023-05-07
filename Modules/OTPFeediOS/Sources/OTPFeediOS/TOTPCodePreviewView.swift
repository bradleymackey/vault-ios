import Combine
import OTPCore
import OTPFeed
import SwiftUI

public struct TOTPCodePreviewView<Updater: CodeTimerUpdater>: View {
    var timerView: CodeTimerHorizontalBarView<Updater>
    @ObservedObject var previewViewModel: CodePreviewViewModel
    var hideCode: Bool

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            OTPCodeLabels(accountName: previewViewModel.accountName, issuer: previewViewModel.issuer)
                .padding(.horizontal, 2)
            codeSection
                .redacted(reason: hideCode ? .placeholder : [])
        }
        .frame(maxWidth: .infinity)
    }

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            CodeTextView(codeState: previewViewModel.code, codeSpacing: 10.0)
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.bold)
                .padding(.horizontal, 2)
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
            case let .error(err, _):
                LoadingBarLabel(text: err.userTitle)
            case .finished, .visible, .notReady:
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
        case .finished, .notReady:
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

struct TOTPCodePreviewView_Previews: PreviewProvider {
    private static let codeRenderer = OTPCodeRendererMock()
    private static let errorRenderer = OTPCodeRendererMock()
    private static let finishedRenderer = OTPCodeRendererMock()

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

            makePreview(issuer: "Finished Example", renderer: finishedRenderer)
                .onAppear {
                    finishedRenderer.subject.send(completion: .finished)
                }

            makePreview(issuer: "Details Hidden", renderer: codeRenderer, hideCode: true)
                .onAppear {
                    finishedRenderer.subject.send(completion: .finished)
                }
        }
        .onAppear {
            updater.subject.send(.init(startTime: 15, endTime: 100))
        }
    }

    static func makePreview(issuer: String?, renderer: OTPCodeRendererMock, hideCode: Bool = false) -> some View {
        let previewViewModel = CodePreviewViewModel(
            accountName: "test@example.com",
            issuer: issuer,
            renderer: renderer
        )
        return TOTPCodePreviewView(
            timerView: CodeTimerHorizontalBarView(
                viewModel: .init(updater: updater, clock: clock),
                color: .blue
            ),
            previewViewModel: previewViewModel,
            hideCode: hideCode
        )
        .frame(width: 250, height: 100)
    }

    static func viewModel(clock: EpochClock) -> CodeTimerViewModel<MockCodeTimerUpdater> {
        CodeTimerViewModel(updater: updater, clock: clock)
    }

    private static let updater: MockCodeTimerUpdater = .init()

    static let clock = EpochClock { 20 }
}
