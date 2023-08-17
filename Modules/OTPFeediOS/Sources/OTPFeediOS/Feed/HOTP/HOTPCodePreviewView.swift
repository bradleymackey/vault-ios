import OTPCore
import OTPFeed
import SwiftUI

struct HOTPCodePreviewView<ButtonView: View>: View {
    var buttonView: ButtonView
    @ObservedObject var previewViewModel: CodePreviewViewModel
    var isEditing: Bool

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleRow
            codeText
            PreviewTimerBarWithText(
                timerView: activeTimerView,
                codeState: previewViewModel.code,
                isEditing: isEditing
            )
        }
        .animation(.easeOut, value: isEditing)
        .onChange(of: scenePhase) { newValue in
            if newValue == .background {
                previewViewModel.hideCodeUntilNextUpdate()
            }
        }
    }

    @ViewBuilder
    private var activeTimerView: some View {
        if isEditing {
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

    private var editLabel: some View {
        ZStack(alignment: .leading) {
            Color.blue
                .frame(height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            LoadingBarLabel(text: localized(key: "action.tapToEdit"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var titleRow: some View {
        HStack(alignment: .center) {
            if case .error = previewViewModel.code {
                CodeErrorIcon()
                    .font(.callout)
            } else {
                CodeIconPlaceholderView(iconFontSize: 8)
                    .clipShape(Circle())
            }
            OTPCodeLabels(accountName: previewViewModel.accountName, issuer: previewViewModel.issuer)
            Spacer()

            buttonView
                .font(canLoadNextCode ? .title.bold() : .title)
                .disabled(!canLoadNextCode)
        }
    }

    private var codeText: some View {
        CodeTextView(codeState: isEditing ? .notReady : previewViewModel.code)
            .font(.system(.largeTitle, design: .monospaced))
            .fontWeight(.bold)
    }

    var canLoadNextCode: Bool {
        previewViewModel.code.allowsNextCodeToBeGenerated && !isEditing
    }
}

struct HOTPCodePreviewView_Previews: PreviewProvider {
    private static let codeRenderer = OTPCodeRendererMock()
    private static let finishedRenderer = OTPCodeRendererMock()
    private static let errorRenderer = OTPCodeRendererMock()

    static var previews: some View {
        VStack(spacing: 20) {
            makePreviewView(accountName: "Normal", renderer: codeRenderer)
                .onAppear {
                    codeRenderer.subject.send("123456")
                }

            makePreviewView(accountName: "Finished", renderer: finishedRenderer)
                .onAppear {
                    finishedRenderer.subject.send(completion: .finished)
                }

            makePreviewView(accountName: "Error", renderer: errorRenderer)
                .onAppear {
                    errorRenderer.subject.send(completion: .failure(NSError(domain: "any", code: 100)))
                }

            makePreviewView(accountName: "Hidden", renderer: codeRenderer, hideCode: true)
        }
    }

    private static func makePreviewView(
        accountName: String,
        renderer: OTPCodeRendererMock,
        hideCode: Bool = false
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
            isEditing: hideCode
        )
        .frame(width: 250, height: 100)
    }
}
