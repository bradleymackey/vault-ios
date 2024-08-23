import Foundation
import ImageTools
import SwiftUI
import VaultFeed

@MainActor
struct BackupKeyExportView: View {
    @State private var viewModel: BackupKeyExportViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: BackupKeyExportViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            exportSection
        }
        .navigationTitle(Text("Export Key"))
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

    private var exportSection: some View {
        Section {
            switch viewModel.exportState {
            case .waiting:
                exportButton
            case let .exported(data):
                QRCodeImage(data: data)
                    .frame(maxWidth: 200)
                    .modifier(HorizontallyCenter())
            case let .error(error):
                exportButton
                Text(error.localizedDescription)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        } footer: {
            Label(
                "Be careful with this private key. It can be used to gain access to your encrypted vault backups.",
                systemImage: "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.red)
        }
    }

    private var exportButton: some View {
        AsyncButton {
            await viewModel.createExport()
        } label: {
            Label("Show Private Key", systemImage: "eye.trianglebadge.exclamationmark.fill")
        }
    }
}
