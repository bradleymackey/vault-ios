import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct BackupImportFlowView: View {
    @State private var viewModel: BackupImportFlowViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: BackupImportFlowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            Text("\(viewModel.importContext)")
        }
        .navigationTitle(Text("Import"))
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .foregroundStyle(.red)
            }
        }
    }
}
