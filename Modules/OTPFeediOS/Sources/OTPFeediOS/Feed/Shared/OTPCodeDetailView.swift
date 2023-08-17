import OTPCore
import OTPFeed
import SwiftUI

public struct OTPCodeDetailView: View {
    @ObservedObject public var viewModel: CodeDetailViewModel

    @StateObject private var editingModel = CodeDetailEditingModel()
    @Environment(\.dismiss) var dismiss

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
        .interactiveDismissDisabled(editingModel.isDirty)
        .toolbar {
            if editingModel.isDirty {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(viewModel.cancelEditsTitle)
                            .tint(.red)
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if editingModel.isDirty {
                    Button {
                        dismiss()
                    } label: {
                        Text(viewModel.saveEditsTitle)
                            .tint(.accentColor)
                    }
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Text(viewModel.doneEditingTitle)
                            .tint(.accentColor)
                    }
                }
            }
        }
    }

    private var iconHeader: some View {
        HStack {
            Spacer()
            CodeIconPlaceholderView(iconFontSize: 22)
                .clipShape(Circle())
            Spacer()
        }
        .padding()
    }

    private var codeDetailSection: some View {
        Section {
            TextField("Site Name", text: $editingModel.detail.issuerTitle)
            TextField("Account Name", text: $editingModel.detail.accountNameTitle)
        } header: {
            iconHeader
        }
    }

    private var descriptionSection: some View {
        Section {
            TextEditor(text: $editingModel.detail.description)
                .frame(height: 200)
        } header: {
            DetailSubtitleView(
                title: localized(key: "codeDetail.description.title"),
                subtitle: localized(key: "codeDetail.description.subtitle")
            )
            .textCase(.none)
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
            DetailSubtitleView(
                title: localized(key: "codeDetail.metadata.title"),
                subtitle: localized(key: "codeDetail.metadata.subtitle")
            )
            .textCase(.none)
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
