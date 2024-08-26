import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct BackupImportFlowView: View {
    @State private var viewModel: BackupImportFlowViewModel
    @State private var isImporting = false

    @Environment(\.dismiss) private var dismiss

    init(viewModel: BackupImportFlowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            Button {
                isImporting = true
            } label: {
                Text("Pick File")
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.pdf]) { result in
                viewModel.handleImport(result: result)
            }

            Text("\(viewModel.state)")
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
