import OTPFeed
import SwiftUI

public struct OTPCodeDetailView<Preview: View>: View {
    public var preview: Preview
    @ObservedObject public var viewModel: CodeDetailViewModel

    public init(preview: Preview, viewModel: CodeDetailViewModel) {
        self.preview = preview
        _viewModel = ObservedObject(initialValue: viewModel)
    }

    public var body: some View {
        Form {
            section
        }
    }

    private var section: some View {
        Section {
            ForEach(viewModel.entries) { entry in
                LabeledContent(entry.title, value: entry.detail)
            }
        } header: {
            preview
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .textCase(nil)
                .foregroundColor(.primary)
        }
    }
}

struct OTPCodeDetailView_Previews: PreviewProvider {
    private static let codeRenderer = OTPCodeRendererMock()

    static var previews: some View {
        OTPCodeDetailView(
            preview: code,
            viewModel: CodeDetailViewModel(code: .init(secret: .empty(), accountName: "Test"))
        )
    }

    static var code: some View {
        let previewViewModel = CodePreviewViewModel(
            accountName: "test@test.com",
            issuer: "Authority",
            renderer: codeRenderer
        )
        return HOTPCodePreviewView(
            buttonView: CodeButtonView(viewModel: .init(hotpRenderer: .init(
                hotpGenerator: .init(secret: Data()),
                initialCounter: 0
            ), counter: 0)),
            previewViewModel: previewViewModel
        )
        .frame(width: 250, height: 100)
        .onAppear {
            codeRenderer.subject.send("123456")
        }
    }
}
