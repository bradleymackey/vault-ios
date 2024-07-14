import Foundation
import SwiftUI
import VaultFeed

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
            TextField("Tag Name...", text: $viewModel.title)
            ColorPicker("Tag Color", selection: $selectedColor)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 16) {
                    ForEach(systemIconOptions, id: \.self) {
                        Image(systemName: $0)
                            .tag($0)
                            .font(.title)
                    }
                }
                .padding(.horizontal, 16)
            }
            .listRowInsets(EdgeInsets())
            .padding(.vertical, 16)
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedColor.hashValue) { _, _ in
            viewModel.color = VaultItemColor(color: selectedColor)
        }
    }
}
