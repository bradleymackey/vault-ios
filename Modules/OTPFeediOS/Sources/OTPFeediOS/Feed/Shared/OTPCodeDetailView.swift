import OTPCore
import OTPFeed
import SwiftUI

public struct OTPCodeDetailView: View {
    @ObservedObject public var viewModel: CodeDetailViewModel

    public init(viewModel: CodeDetailViewModel) {
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
