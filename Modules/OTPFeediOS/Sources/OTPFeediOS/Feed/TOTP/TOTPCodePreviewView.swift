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
        .animation(.easeOut, value: hideCode)
    }

    private var labelsStack: some View {
        HStack(alignment: .center, spacing: 6) {
            if case .error = previewViewModel.code {
                CodeErrorIcon()
                    .font(.callout)
            } else {
                CodeIconPlaceholderView(iconFontSize: 8)
                    .clipShape(Circle())
            }
            OTPCodeLabels(accountName: previewViewModel.accountName, issuer: previewViewModel.issuer)
            Spacer()
        }
        .padding(.horizontal, 2)
        .padding(.top, 6)
    }

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            CodeTextView(codeState: hideCode ? .notReady : previewViewModel.code)
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.bold)
                .padding(.horizontal, 2)
                .foregroundColor(.primary)

            PreviewTimerBarWithText(
                timerView: activeTimerView,
                codeState: previewViewModel.code,
                isEditing: hideCode
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var activeTimerView: some View {
        if hideCode {
            Color.blue
                .transition(.move(edge: .leading))
        } else {
            switch previewViewModel.code {
            case .visible:
                timerView
                    .transition(.opacity)
            case .finished, .notReady, .obfuscated:
                Color.gray
                    .redacted(reason: .placeholder)
                    .transition(.opacity)
            case .error:
                Color.red
                    .transition(.opacity)
            }
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
                .modifier(OTPCardViewModifier())
                .onAppear {
                    codeRenderer.subject.send("1234567")
                }

            makePreview(issuer: nil, renderer: codeRenderer)

            makePreview(issuer: "Code Error Example", renderer: errorRenderer)
                .modifier(OTPCardViewModifier())
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
            subject.send(.init(startTime: 15, endTime: 100))
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
            timerView: CodeTimerHorizontalBarView(
                timerState: CodeTimerPeriodState(clock: clock, statePublisher: subject.eraseToAnyPublisher()),
                color: .blue
            ),
            hideCode: hideCode
        )
        .frame(width: 250, height: 100)
    }

    private static let subject: PassthroughSubject<OTPTimerState, Never> = .init()

    static let clock = EpochClock { 20 }
}
