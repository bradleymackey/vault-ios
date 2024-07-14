import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct VaultTagDetailView<Store: VaultTagStore>: View {
    @State private var viewModel: VaultTagDetailViewModel<Store>
    @State private var selectedColor: Color

    init(viewModel: VaultTagDetailViewModel<Store>) {
        self.viewModel = viewModel
        _selectedColor = State(initialValue: .brown)
    }

    var systemIconOptions: [String] = [
        "tag.fill",
        "clock.fill",
        "person.fill",
    ]

    var body: some View {
        Form {
            pickerSection
            iconSection
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.inline)
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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 32))], spacing: 40) {
            ForEach(systemIconOptions, id: \.self) { icon in
                Image(systemName: icon)
                    .resizable()
                    .font(.title)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
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
