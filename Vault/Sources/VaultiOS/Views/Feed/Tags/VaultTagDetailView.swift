import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct VaultTagDetailView: View {
    @State private var viewModel: VaultTagDetailViewModel
    @State private var selectedColor: Color

    @Environment(\.dismiss) private var dismiss

    init(viewModel: VaultTagDetailViewModel) {
        self.viewModel = viewModel
        _selectedColor = State(initialValue: viewModel.color.color)
    }

    var body: some View {
        Form {
            previewSection
            tagNameSection
            iconSection
            if viewModel.isExistingItem {
                deleteSection
            }
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AsyncButton {
                    await viewModel.save()
                    dismiss()
                } label: {
                    Text("Save")
                }
                .disabled(!viewModel.isValidToSave)
            }

            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }
            }
        }
        .onChange(of: selectedColor.hashValue) { _, _ in
            viewModel.color = VaultItemColor(color: selectedColor)
        }
    }

    private var previewSection: some View {
        Section {
            VStack(alignment: .center, spacing: 16) {
                TagPillView(
                    tag: .init(
                        id: .init(),
                        name: viewModel.title,
                        color: viewModel.color,
                        iconName: viewModel.systemIconName
                    ),
                    isSelected: true
                )

                ColorPicker("Tag Color", selection: $selectedColor)
                    .labelsHidden()
            }
            .modifier(HorizontallyCenter())
        }
        .listRowBackground(EmptyView())
    }

    private var tagNameSection: some View {
        Section {
            TextField("My Tag", text: $viewModel.title)
        } header: {
            Text("Tag Name")
        }
    }

    private var iconSection: some View {
        Section {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70, maximum: 100))], spacing: 12) {
                ForEach(viewModel.systemIconOptions, id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.system(.title2))
                        .padding(8)
                        .foregroundStyle(
                            viewModel.systemIconName == icon ? selectedColor : Color(UIColor.tertiaryLabel)
                                .opacity(0.5)
                        )
                        .onTapGesture {
                            viewModel.systemIconName = icon
                        }
                }
            }
        } header: {
            Text("Icon")
        }
    }

    private var deleteSection: some View {
        Section {
            AsyncButton {
                await viewModel.delete()
                dismiss()
            } label: {
                FormRow(image: .init(systemName: "trash.fill"), color: .red, style: .standard) {
                    Text("Delete Tag")
                }
                .foregroundStyle(.red)
            }
        }
    }
}
