import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct VaultTagDetailView<Store: VaultTagStore>: View {
    @State private var viewModel: VaultTagDetailViewModel<Store>
    @State private var selectedColor: Color

    @Environment(\.dismiss) private var dismiss

    init(viewModel: VaultTagDetailViewModel<Store>) {
        self.viewModel = viewModel
        _selectedColor = State(initialValue: .brown)
    }

    var body: some View {
        Form {
            pickerSection
            iconSection
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await viewModel.save()
                    }
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

    private var pickerSection: some View {
        Section {
            TextField("Enter tag name...", text: $viewModel.title)
            ColorPicker("Tag Color", selection: $selectedColor)
        }
    }

    private var iconSection: some View {
        Section {
            systemIconPicker
        } header: {
            Text("Icon")
        }
    }

    private var systemIconPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
            ForEach(viewModel.systemIconOptions, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.title)
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
                    .foregroundStyle(viewModel.systemIconName == icon ? selectedColor : .secondary)
                    .background(
                        Circle()
                            .stroke(selectedColor, lineWidth: viewModel.systemIconName == icon ? 2 : 0)
                    )
                    .onTapGesture {
                        viewModel.systemIconName = icon
                    }
            }
        }
    }
}
