import Combine
import OTPCore
import OTPFeed
import SwiftUI

public struct TOTPCodePreviewView<TimerBar: View>: View {
    @ObservedObject var previewViewModel: CodePreviewViewModel
    var timerView: TimerBar
    var hideCode: Bool

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelsStack
            codeSection
        }
        .frame(maxWidth: .infinity)
    }

    private var labelsStack: some View {
        HStack(alignment: .center) {
            OTPCodeLabels(accountName: previewViewModel.accountName, issuer: previewViewModel.issuer)
            Spacer()
            if case .error = effectiveCodeState {
                CodeErrorIcon()
                    .font(.title)
            }
        }
        .padding(.horizontal, 2)
    }

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                previewViewModel.didTapCode()
            } label: {
                CodeTextView(codeState: effectiveCodeState)
                    .font(.system(.largeTitle, design: .monospaced))
                    .fontWeight(.bold)
                    .padding(.horizontal, 2)
            }
            .foregroundColor(.primary)
            .disabled(!effectiveCodeState.isVisible || !previewViewModel.allowsCodeTapAction)

            timerSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var effectiveCodeState: OTPCodeState {
        if hideCode {
            return .finished
        } else {
            return previewViewModel.code
        }
    }

    @ViewBuilder
    private var timerSection: some View {
        ZStack(alignment: .leading) {
            activeTimerView
                .frame(height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            switch effectiveCodeState {
            case let .error(err, _):
                LoadingBarLabel(text: err.userTitle)
            case .finished, .visible, .notReady:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var activeTimerView: some View {
        switch effectiveCodeState {
        case .visible:
            timerView
        case .finished, .notReady:
            timerView.redacted(reason: .placeholder)
        case .error:
            Color.red
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
                    codeRenderer.subject.send("1234567")
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
            previewViewModel: previewViewModel,
            timerView: Color.red,
            hideCode: hideCode
        )
        .frame(width: 250, height: 100)
    }

    private static let updater: MockCodeTimerUpdater = .init()

    static let clock = EpochClock { 20 }
}
