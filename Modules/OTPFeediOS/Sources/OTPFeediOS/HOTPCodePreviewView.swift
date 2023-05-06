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
                    .font(.title.bold())
            }
        }
    }
}

struct HOTPCodePreviewView_Previews: PreviewProvider {
    private static let codeRenderer = OTPCodeRendererMock()

    static var previews: some View {
        VStack(spacing: 20) {
            HOTPCodePreviewView(
                accountName: "test@test.com",
                issuer: "Authority",
                textView: CodeTextView(viewModel: .init(renderer: codeRenderer), codeSpacing: 10.0),
                buttonView: CodeButtonView(viewModel: .init(hotpRenderer: .init(
                    hotpGenerator: .init(secret: Data()),
                    initialCounter: 0
                ), counter: 0)),
                previewViewModel: .init(renderer: codeRenderer)
            )
            .frame(width: 250, height: 100)
        }
        .onAppear {
            codeRenderer.subject.send("123456")
        }
    }
}
