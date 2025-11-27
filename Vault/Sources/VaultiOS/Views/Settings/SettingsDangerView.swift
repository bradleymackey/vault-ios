import Foundation
import SwiftUI
import Toasts
import VaultFeed

struct SettingsDangerView: View {
    private var viewModel: SettingsDangerViewModel
    @State private var deleteError: PresentationError?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentToast) private var presentToast

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
                subtitle: "Be careful what you do here.",
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
                    withAnimation {
                        deleteError = nil
                    }
                    try await viewModel.deleteEntireVault()
                    let deletedToast = ToastValue(icon: Image(systemName: "checkmark"), message: "Vault Deleted")
                    presentToast(deletedToast)
                    dismiss()
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

            if let deleteError {
                Group {
                    Text(deleteError.userDescription ?? "Error deleting data.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
