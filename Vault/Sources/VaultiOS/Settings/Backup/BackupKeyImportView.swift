import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct BackupKeyImportView: View {
    @State private var viewModel: BackupKeyImportViewModel
    @Environment(\.dismiss) private var dismiss

    init(store: any BackupPasswordStore) {
        _viewModel = .init(initialValue: .init(importer: BackupPasswordImporterImpl(store: store)))
    }

    var body: some View {
        Form {
            importSection
        }
        .navigationTitle(Text("Import Password"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                }
            }
        }
    }

    private var importSection: some View {
        Section {
            Text("Import")
        } header: {
            Text("Scanner UI here")
        }
    }
}
