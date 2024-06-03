import Foundation
import SwiftUI
import VaultFeed
import VaultUI

@MainActor
struct BackupKeyChangeView: View {
    @State private var viewModel: BackupKeyChangeViewModel

    init(store: any BackupPasswordStore) {
        _viewModel = .init(initialValue: .init(store: store, deriverFactory: ApplicationKeyDeriverFactoryImpl()))
    }

    var body: some View {
        Form {
            passwordSection
            keySection
            detailsSection
        }
        .navigationTitle(Text("Backup Password"))
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.newPassword.isLoading)
        .animation(.easeOut, value: viewModel.newlyEnteredPassword.isNotEmpty)
        .task {
            viewModel.loadInitialData()
        }
    }

    private var passwordSection: some View {
        Section {
            SecureField("New Password", text: $viewModel.newlyEnteredPassword)
                .disabled(viewModel.newPassword.isLoading)

            if viewModel.newlyEnteredPassword.isNotEmpty {
                SecureField("Confirm Password", text: $viewModel.newlyEnteredPasswordConfirm)
                    .disabled(viewModel.newPassword.isLoading)
            }

        } footer: {
            StandaloneButton {
                await viewModel.saveEnteredPassword()
            } content: {
                if !viewModel.newPassword.isLoading {
                    Text("Update Password")
                } else {
                    HStack(alignment: .center, spacing: 8) {
                        ProgressView()
                        Text("Generating")
                            .shimmering(active: viewModel.newPassword.isLoading)
                    }
                }
            }
            .animation(.none, value: viewModel.newPassword)
            .disabled(viewModel.newPassword.isLoading)
            .padding()
            .modifier(HorizontallyCenter())
        }
        .animation(.easeOut, value: viewModel.newlyEnteredPassword)
        .transition(.move(edge: .leading))
    }

    private var keySection: some View {
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

    private var detailsSection: some View {
        Section {
            DisclosureGroup {
                Group {
                    Text("Your password is used to generate an encryption key that is used to secure your vault.")
                    Text(
                        "For security, this key generation process may take up to 3 minutes, even on a very fast device."
                    )
                    Text(
                        "The encryption key is not automatically synced between devices, it must be shared manually. This is also for security."
                    )
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            } label: {
                Label("About", systemImage: "questionmark.circle.fill")
            }

            DisclosureGroup {
                LabeledContent {
                    Text(viewModel.encryptionKeyDeriverSignature.userVisibleDescription)
                } label: {
                    Text("Algorithm")
                }

                LabeledContent {
                    Text(viewModel.encryptionKeyDeriverSignature.id)
                        .font(.caption2)
                        .fontDesign(.monospaced)
                } label: {
                    Text("ID")
                }
            } label: {
                Label("Keygen Information", systemImage: "questionmark.key.filled")
            }
        }
    }
}
