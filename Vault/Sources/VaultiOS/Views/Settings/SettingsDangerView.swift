import Foundation
import SwiftUI
import VaultFeed

struct SettingsDangerView: View {
    private var viewModel: SettingsDangerViewModel
    @State private var deleteError: PresentationError?
    @State private var deleteAllSuccess = false

    init(viewModel: SettingsDangerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            headerSection
        }
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.isDeleting)
    }

    private var headerSection: some View {
        Section {
            PlaceholderView(
                systemIcon: "exclamationmark.triangle.fill",
                title: "Danger Zone",
                subtitle: "Be careful what you do here."
            )
            .padding()
            .containerRelativeFrame(.horizontal)
            .foregroundStyle(.red)
        } footer: {
            VStack(alignment: .center, spacing: 16) {
                deleteAllButton
            }
            .padding(16)
        }
    }

    private var deleteAllButton: some View {
        VStack(alignment: .center, spacing: 8) {
            AsyncButton {
                do {
                    deleteAllSuccess = false
                    withAnimation {
                        deleteError = nil
                    }
                    try await viewModel.deleteEntireVault()
                    deleteAllSuccess = true
                } catch let error as PresentationError {
                    withAnimation {
                        deleteError = error
                    }
                }
            } label: {
                Label("Delete All Data", systemImage: "trash.fill")
            } loading: {
                ProgressView()
                    .tint(.white)
            }
            .modifier(ProminentButtonModifier(color: .red))

            Group {
                if deleteAllSuccess {
                    Label("Vault deleted successfully", systemImage: "checkmark")
                } else if let deleteError {
                    Text(deleteError.userDescription ?? "Error deleting data.")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
