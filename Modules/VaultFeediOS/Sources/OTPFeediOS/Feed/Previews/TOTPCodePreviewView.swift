import Combine
import OTPFeed
import SwiftUI
import VaultCore

@MainActor
public struct TOTPCodePreviewView<TimerBar: View>: View {
    var previewViewModel: CodePreviewViewModel
    var timerView: TimerBar
    var behaviour: VaultItemViewBehaviour

    @Namespace private var codeTimerAnimation

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelsStack
            codeSection
        }
        .frame(maxWidth: .infinity)
        .animation(.easeOut, value: behaviour)
    }

    private var labelsStack: some View {
        HStack(alignment: .top, spacing: 6) {
            icon
                .padding(.top, 2)
            OTPCodeLabels(accountName: previewViewModel.accountName, issuer: previewViewModel.issuer)
            Spacer()
        }
        .padding(.horizontal, 2)
        .padding(.top, 6)
    }

    @ViewBuilder
    private var icon: some View {
        if case .error = previewViewModel.code {
            CodeErrorIcon()
                .font(.callout)
        } else {
            CodeIconPlaceholderView(iconFontSize: 8)
                .clipShape(Circle())
        }
    }

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            CodeTextView(codeState: behaviour != .normal ? .notReady : previewViewModel.code)
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.bold)
                .padding(.horizontal, 2)
                .foregroundColor(.primary)

            CodeStateTimerBarView(
                timerView: activeTimerView,
                codeState: previewViewModel.code,
                behaviour: behaviour
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var activeTimerView: some View {
        switch behaviour {
        case .normal:
            switch previewViewModel.code {
            case .visible:
                timerView
                    .matchedGeometryEffect(id: "Timer", in: codeTimerAnimation)
            case .finished, .notReady, .obfuscated:
                Color.gray
                    .redacted(reason: .placeholder)
                    .matchedGeometryEffect(id: "Timer", in: codeTimerAnimation)
            case .error:
                Color.red
                    .matchedGeometryEffect(id: "Timer", in: codeTimerAnimation)
            }
        case .obfuscate:
            Color.blue
                .matchedGeometryEffect(id: "Timer", in: codeTimerAnimation)
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

            makePreview(issuer: "Working Example with Very long title and stuff", renderer: codeRenderer)
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

            makePreview(issuer: "Obfuscated", renderer: codeRenderer, behaviour: .obfuscate(message: "Editing..."))
                .onAppear {
                    finishedRenderer.subject.send(completion: .finished)
                }

            makePreview(issuer: "Obfuscated (no msg)", renderer: codeRenderer, behaviour: .obfuscate(message: nil))
                .onAppear {
                    finishedRenderer.subject.send(completion: .finished)
                }
        }
        .onAppear {
            subject.send(.init(startTime: 15, endTime: 100))
        }
    }

    static func makePreview(
        issuer: String?,
        renderer: OTPCodeRendererMock,
        behaviour: VaultItemViewBehaviour = .normal
    ) -> some View {
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
            behaviour: behaviour
        )
        .frame(width: 250, height: 100)
    }

    private static let subject: PassthroughSubject<OTPTimerState, Never> = .init()

    static let clock = EpochClock { 20 }
}
