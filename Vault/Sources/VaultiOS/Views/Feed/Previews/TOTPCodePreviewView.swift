import Combine
import SwiftUI
import VaultCore
import VaultFeed

@MainActor
public struct TOTPCodePreviewView<TimerBar: View>: View {
    var previewViewModel: OTPCodePreviewViewModel
    var timerView: TimerBar
    var behaviour: VaultItemViewBehaviour

    @Namespace private var codeTimerAnimation

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelsStack
            Spacer()
            codeSection
            Spacer()
            CodeStateTimerBarView(
                timerView: activeTimerView,
                codeState: previewViewModel.code,
                behaviour: behaviour
            )
        }
        .animation(.easeOut, value: behaviour)
        .aspectRatio(1, contentMode: .fill)
        .shimmering(active: isEditing)
    }

    private var labelsStack: some View {
        HStack(alignment: .top, spacing: 6) {
            icon
                .padding(.top, 2)
            OTPCodeLabels(accountName: previewViewModel.accountName, issuer: previewViewModel.visibleIssuer)
                .foregroundStyle(isEditing ? .white : .primary)
            Spacer()
        }
        .padding(.horizontal, 2)
        .padding(.top, 6)
    }

    @ViewBuilder
    private var icon: some View {
        if case .error = previewViewModel.code {
            PreviewErrorIcon()
                .font(.callout)
        } else {
            OTPCodeIconPlaceholderView(iconFontSize: 8, backgroundColor: previewViewModel.color.color)
                .clipShape(Circle())
        }
    }

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            OTPCodeTextView(codeState: behaviour != .normal ? .notReady : previewViewModel.code)
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.bold)
                .padding(.horizontal, 2)
                .foregroundColor(isEditing ? .white : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var activeTimerView: some View {
        switch behaviour {
        case .normal:
            switch previewViewModel.code {
            case .visible:
                timerView
            case .finished, .notReady, .obfuscated:
                Color.gray
                    .redacted(reason: .placeholder)
            case .error:
                Color.red
            }
        case .editingState:
            Color.white
        }
    }

    private var isEditing: Bool {
        switch behaviour {
        case .normal: false
        case .editingState: true
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
                .modifier(VaultCardModifier())
                .onAppear {
                    codeRenderer.subject.send("1234567")
                }

            makePreview(issuer: "Working Example with Very long title and stuff", renderer: codeRenderer)
                .modifier(VaultCardModifier())
                .onAppear {
                    codeRenderer.subject.send("1234567")
                }

            makePreview(issuer: "", renderer: codeRenderer)

            makePreview(issuer: "Code Error Example", renderer: errorRenderer)
                .modifier(VaultCardModifier())
                .onAppear {
                    errorRenderer.subject.send(completion: .failure(NSError(domain: "sdf", code: 1)))
                }

            makePreview(issuer: "Finished Example", renderer: finishedRenderer)
                .onAppear {
                    finishedRenderer.subject.send(completion: .finished)
                }

            makePreview(issuer: "Obfuscated", renderer: codeRenderer, behaviour: .editingState(message: "Editing..."))
                .onAppear {
                    finishedRenderer.subject.send(completion: .finished)
                }

            makePreview(issuer: "Obfuscated (no msg)", renderer: codeRenderer, behaviour: .editingState(message: nil))
                .onAppear {
                    finishedRenderer.subject.send(completion: .finished)
                }
        }
        .onAppear {
            subject.send(.init(startTime: 15, endTime: 100))
        }
    }

    static func makePreview(
        issuer: String,
        renderer: OTPCodeRendererMock,
        behaviour: VaultItemViewBehaviour = .normal
    ) -> some View {
        let previewViewModel = OTPCodePreviewViewModel(
            accountName: "test@example.com",
            issuer: issuer,
            color: .default,
            renderer: renderer
        )
        return TOTPCodePreviewView(
            previewViewModel: previewViewModel,
            timerView: CodeTimerHorizontalBarView(
                timerState: OTPCodeTimerPeriodState(clock: clock, statePublisher: subject.eraseToAnyPublisher()),
                color: .blue
            ),
            behaviour: behaviour
        )
        .frame(width: 250, height: 100)
    }

    private static let subject: PassthroughSubject<OTPCodeTimerState, Never> = .init()

    static let clock = EpochClock { 20 }
}
