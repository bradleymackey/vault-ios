import OTPFeed
import SwiftUI
import VaultCore

@MainActor
struct HOTPCodePreviewView<ButtonView: View>: View {
    var buttonView: ButtonView
    var previewViewModel: CodePreviewViewModel
    var behaviour: VaultItemViewBehaviour

    @Namespace private var codeTimerAnimation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelsStack
            codeText
            CodeStateTimerBarView(
                timerView: activeTimerView,
                codeState: previewViewModel.code,
                behaviour: behaviour
            )
        }
        .animation(.easeOut, value: behaviour)
    }

    @ViewBuilder
    private var activeTimerView: some View {
        switch behaviour {
        case .normal:
            switch previewViewModel.code {
            case .visible:
                Color.blue
                    .matchedGeometryEffect(id: "Timer", in: codeTimerAnimation)
            case .notReady, .obfuscated:
                Color.gray
                    .matchedGeometryEffect(id: "Timer", in: codeTimerAnimation)
            case .error, .finished:
                Color.red
                    .matchedGeometryEffect(id: "Timer", in: codeTimerAnimation)
            }
        case .obfuscate:
            Color.blue
                .matchedGeometryEffect(id: "Timer", in: codeTimerAnimation)
        }
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

    private var codeText: some View {
        HStack(alignment: .center) {
            CodeTextView(codeState: behaviour != .normal ? .notReady : previewViewModel.code)
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
            buttonView
                .font(canLoadNextCode ? .title.bold() : .title)
                .disabled(!canLoadNextCode)
        }
    }

    var canLoadNextCode: Bool {
        previewViewModel.code.allowsNextCodeToBeGenerated && behaviour == .normal
    }
}

struct HOTPCodePreviewView_Previews: PreviewProvider {
    private static let codeRenderer = OTPCodeRendererMock()
    private static let finishedRenderer = OTPCodeRendererMock()
    private static let errorRenderer = OTPCodeRendererMock()

    static var previews: some View {
        VStack(spacing: 20) {
            makePreviewView(accountName: "Normal", renderer: codeRenderer)
                .modifier(OTPCardViewModifier())
                .onAppear {
                    codeRenderer.subject.send("123456")
                }

            makePreviewView(accountName: "Finished", renderer: finishedRenderer)
                .modifier(OTPCardViewModifier())
                .onAppear {
                    finishedRenderer.subject.send(completion: .finished)
                }

            makePreviewView(accountName: "Error", renderer: errorRenderer)
                .onAppear {
                    errorRenderer.subject.send(completion: .failure(NSError(domain: "any", code: 100)))
                }

            makePreviewView(accountName: "Obfuscate", renderer: codeRenderer, behaviour: .obfuscate(message: "editing"))

            makePreviewView(
                accountName: "Obfuscate (no msg)",
                renderer: codeRenderer,
                behaviour: .obfuscate(message: nil)
            )
        }
    }

    private static func makePreviewView(
        accountName: String,
        renderer: OTPCodeRendererMock,
        behaviour: VaultItemViewBehaviour = .normal
    ) -> some View {
        let previewViewModel = CodePreviewViewModel(
            accountName: accountName,
            issuer: "Authority",
            renderer: renderer
        )
        return HOTPCodePreviewView(
            buttonView: CodeButtonView(
                viewModel: .init(
                    hotpRenderer: .init(
                        hotpGenerator: .init(secret: Data())
                    ),
                    timer: LiveIntervalTimer(),
                    initialCounter: 0
                )
            ),
            previewViewModel: previewViewModel,
            behaviour: behaviour
        )
        .frame(width: 250, height: 100)
    }
}
