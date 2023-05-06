import OTPFeed
import SwiftUI

struct HOTPCodePreviewView: View {
    var accountName: String
    var issuer: String?
    var textView: CodeTextView
    var buttonView: CodeButtonView
    @ObservedObject var previewViewModel: CodePreviewViewModel

    var body: some View {
        HStack(alignment: .center) {
            labels
        }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 8) {
            OTPCodeLabels(accountName: accountName, issuer: issuer)
            HStack(alignment: .firstTextBaseline) {
                textView
                    .font(.system(.largeTitle, design: .monospaced))
                    .fontWeight(.bold)
                Spacer()
                buttonView
                    .font(canLoadNextCode ? .title.bold() : .title)
                    .disabled(!canLoadNextCode)
            }
        }
    }

    var canLoadNextCode: Bool {
        previewViewModel.code.allowsNextCodeToBeGenerated
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
                    finishedRenderer.subject.send(completion: .failure(NSError(domain: "any", code: 100)))
                }
        }
    }

    private static func makePreviewView(accountName: String, renderer: OTPCodeRendererMock) -> some View {
        let previewViewModel = CodePreviewViewModel(renderer: renderer)
        return HOTPCodePreviewView(
            accountName: accountName,
            issuer: "Authority",
            textView: CodeTextView(viewModel: previewViewModel, codeSpacing: 10.0),
            buttonView: CodeButtonView(viewModel: .init(hotpRenderer: .init(
                hotpGenerator: .init(secret: Data()),
                initialCounter: 0
            ), counter: 0)),
            previewViewModel: previewViewModel
        )
        .frame(width: 250, height: 100)
    }
}
