import OTPCore
import OTPFeed
import SwiftUI

struct HOTPCodePreviewView<ButtonView: View>: View {
    var buttonView: ButtonView
    @ObservedObject var previewViewModel: CodePreviewViewModel
    var hideCode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleRow
            codeText
            timerSection
        }
        .animation(.none, value: hideCode)
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
            case .editing:
                LoadingBarLabel(text: localized(key: "action.tapToEdit"))
            case .finished, .visible, .notReady:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var activeTimerView: some View {
        switch effectiveCodeState {
        case .visible, .editing:
            Color.blue
        case .notReady:
            Color.gray
        case .error, .finished:
            Color.red
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
            OTPCodeLabels(accountName: previewViewModel.accountName, issuer: previewViewModel.issuer)
            Spacer()
            if case .error = effectiveCodeState {
                CodeErrorIcon()
                    .font(.title)
            }

            buttonView
                .font(canLoadNextCode ? .title.bold() : .title)
                .disabled(!canLoadNextCode)
        }
    }

    private var effectiveCodeState: OTPCodeState {
        if hideCode {
            return .editing
        } else {
            return previewViewModel.code
        }
    }

    private var codeText: some View {
        CodeTextView(codeState: effectiveCodeState)
            .font(.system(.largeTitle, design: .monospaced))
            .fontWeight(.bold)
    }

    var canLoadNextCode: Bool {
        effectiveCodeState.allowsNextCodeToBeGenerated && !hideCode
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
                        hotpGenerator: .init(secret: Data()),
                        initialCounter: 0
                    ),
                    timer: LiveIntervalTimer(),
                    initialCounter: 0
                )
            ),
            previewViewModel: previewViewModel,
            hideCode: hideCode
        )
        .frame(width: 250, height: 100)
    }
}
