import OTPCore
import OTPFeed
import SwiftUI

struct HOTPCodePreviewView<ButtonView: View>: View {
    var buttonView: ButtonView
    @ObservedObject var previewViewModel: CodePreviewViewModel
    var behaviour: OTPViewBehaviour?

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelsStack
            codeText
            PreviewTimerBarWithText(
                timerView: activeTimerView,
                codeState: previewViewModel.code,
                behaviour: behaviour
            )
        }
        .animation(.easeOut, value: behaviour)
        .onChange(of: scenePhase) { newValue in
            if newValue == .background {
                previewViewModel.hideCodeUntilNextUpdate()
            }
        }
    }

    @ViewBuilder
    private var activeTimerView: some View {
        if behaviour != nil {
            Color.blue
                .transition(.identity)
        } else {
            switch previewViewModel.code {
            case .visible:
                Color.blue
                    .transition(.identity)
            case .notReady, .obfuscated:
                Color.gray
            case .error, .finished:
                Color.red
            }
        }
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

    private var codeText: some View {
        HStack(alignment: .center) {
            CodeTextView(codeState: behaviour != nil ? .notReady : previewViewModel.code)
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
        previewViewModel.code.allowsNextCodeToBeGenerated && behaviour == nil
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
        behaviour: OTPViewBehaviour? = nil
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
