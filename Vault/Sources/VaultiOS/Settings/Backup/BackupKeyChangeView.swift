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
                TextField("Password", text: $viewModel.newlyEnteredPassword)
                    .disabled(viewModel.newPassword.isLoading)

                Button {
                    Task {
                        await viewModel.saveEnteredPassword()
                        viewModel.newlyEnteredPassword = ""
                    }
                } label: {
                    Text(viewModel.newPassword.isLoading ? "Generating" : "Update")
                }
                .disabled(viewModel.newPassword.isLoading)
                .shimmering(active: viewModel.newPassword.isLoading)
            } header: {
                Text("Update password")
            } footer: {
                Text(viewModel.encryptionKeyDeriverDescription)
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
                Text("Current encryption key and salt")
            }
        }
        .task {
            viewModel.loadInitialData()
        }
    }
}
