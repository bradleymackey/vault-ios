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
        }
    }

    private var titleRow: some View {
        HStack(alignment: .center) {
            OTPCodeLabels(accountName: previewViewModel.accountName, issuer: previewViewModel.issuer)
            Spacer()
            if case .error = previewViewModel.code {
                CodeErrorIcon()
                    .font(.title)
            } else if !hideCode {
                buttonView
                    .font(canLoadNextCode ? .title.bold() : .title)
                    .disabled(!canLoadNextCode)
            }
        }
    }

    private var codeText: some View {
        CodeTextView(codeState: previewViewModel.code)
            .font(.system(.largeTitle, design: .monospaced))
            .fontWeight(.bold)
            .redacted(reason: hideCode ? .placeholder : [])
    }

    var canLoadNextCode: Bool {
        previewViewModel.code.allowsNextCodeToBeGenerated && !hideCode
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
            buttonView: CodeButtonView(viewModel: .init(hotpRenderer: .init(
                hotpGenerator: .init(secret: Data()),
                initialCounter: 0
            ), counter: 0)),
            previewViewModel: previewViewModel,
            hideCode: hideCode
        )
        .frame(width: 250, height: 100)
    }
}
