import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct BackupKeyChangeView: View {
    @State private var viewModel: BackupKeyChangeViewModel

    init(store: any BackupPasswordStore) {
        _viewModel = .init(initialValue: .init(store: store))
    }

    var body: some View {
        Form {
            Section {
                switch viewModel.newPassword {
                case .neutral, .error, .creating:
                    TextField("Password", text: $viewModel.newlyEnteredPassword)
                        .disabled(viewModel.newPassword.isLoading)
                case .success:
                    Text("Updated!")
                }

                Button {
                    Task {
                        await viewModel.saveEnteredPassword()
                    }
                } label: {
                    Text(viewModel.newPassword.isLoading ? "Generating" : "Update")
                }
                .disabled(viewModel.newPassword.isLoading)
                .shimmering(active: viewModel.newPassword.isLoading)
            } header: {
                Text("Update password")
            }

            Section {
                switch viewModel.existingPassword {
                case .loading:
                    Text("Loading")
                case let .hasExistingPassword(backupPassword):
                    Text(backupPassword.key.toHexString())
                    Text(backupPassword.salt.toHexString())
                case .noExistingPassword:
                    Text("None")
                case .errorFetching:
                    Text("Error")
                }
            } header: {
                Text("Existing key")
            }
        }
        .task {
            viewModel.loadInitialData()
        }
    }
}
