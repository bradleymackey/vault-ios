import OTPCore
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
            Label {
                LabeledContent(viewModel.createdDateTitle, value: viewModel.createdDateValue)
            } icon: {
                Image(systemName: "clock")
                    .foregroundColor(.primary)
            }

            Label {
                LabeledContent(viewModel.updatedDateTitle, value: viewModel.updatedDateValue)
            } icon: {
                Image(systemName: "clock")
                    .foregroundColor(.primary)
            }

            ForEach(viewModel.detailMenuItems) { item in
                DisclosureGroup {
                    ForEach(item.entries) { entry in
                        Label {
                            LabeledContent(entry.title, value: entry.detail)
                        } icon: {
                            Image(systemName: entry.systemIconName)
                                .foregroundColor(.primary)
                        }
                    }
                } label: {
                    Label {
                        Text(item.title)
                    } icon: {
                        Image(systemName: item.systemIconName)
                            .foregroundColor(.primary)
                    }
                }
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
            viewModel: CodeDetailViewModel(
                storedCode: .init(
                    id: UUID(),
                    created: Date(),
                    updated: Date(),
                    userDescription: "Description",
                    code: .init(secret: .empty(), accountName: "Test")
                )
            )
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
                hotpGenerator: .init(secret: Data())
            ), timer: LiveIntervalTimer(), initialCounter: 0)),
            previewViewModel: previewViewModel,
            isEditing: false
        )
        .frame(width: 250, height: 100)
        .onAppear {
            codeRenderer.subject.send("123456")
        }
    }
}
