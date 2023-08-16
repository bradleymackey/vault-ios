import OTPCore
import OTPFeed
import SwiftUI

public struct OTPCodeDetailView: View {
    @ObservedObject public var viewModel: CodeDetailViewModel

    @State private var siteName: String = "Site name"
    @State private var accountName: String = "Account name"
    @State private var description: String = "Description"

    public init(viewModel: CodeDetailViewModel) {
        _viewModel = ObservedObject(initialValue: viewModel)
    }

    public var body: some View {
        Form {
            codeDetailSection
            descriptionSection
            metadataSection
        }
        .navigationTitle(localized(key: "codeDetail.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var iconHeader: some View {
        HStack {
            Spacer()
            ZStack {
                Color.gray
                Image(systemName: "key.horizontal.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 22))
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            Spacer()
        }
        .padding()
    }

    private var codeDetailSection: some View {
        Section {
            TextField("Site Name", text: $siteName)
            TextField("Account Name", text: $accountName)
        } header: {
            iconHeader
        }
    }

    private var descriptionSection: some View {
        Section {
            TextEditor(text: $description)
                .frame(height: 200)
        } header: {
            Text(localized(key: "codeDetail.description.title"))
        }
    }

    private var metadataSection: some View {
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
            Text(localized(key: "codeDetail.metadata.title"))
        }
    }
}

struct OTPCodeDetailView_Previews: PreviewProvider {
    private static let codeRenderer = OTPCodeRendererMock()

    static var previews: some View {
        OTPCodeDetailView(
            viewModel: CodeDetailViewModel(
                storedCode: .init(
                    id: UUID(),
                    created: Date(),
                    updated: Date(),
                    userDescription: "Description",
                    code: .init(type: .totp(), secret: .empty(), accountName: "Test")
                )
            )
        )
    }
}
