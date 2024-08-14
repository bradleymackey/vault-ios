import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct BackupKeyChangeView: View {
    @State private var viewModel: BackupKeyChangeViewModel
    @State private var keyGenerationTask: Task<Void, Never>?

    @Environment(\.dismiss) private var dismiss

    init(viewModel: BackupKeyChangeViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            switch viewModel.permissionState {
            case .loading:
                PlaceholderView(systemIcon: "lock.fill", title: "Locked")
                    .foregroundStyle(.secondary)
                    .padding()
                    .containerRelativeFrame(.horizontal)
            case .allowed:
                passwordSection
                detailsSection
            case .denied:
                PlaceholderView(
                    systemIcon: "lock.slash.fill",
                    title: "Authentication Failed",
                    subtitle: "Please try again"
                )
                .containerRelativeFrame(.horizontal)
                .foregroundStyle(.secondary)
                .padding()
            }
        }
        .navigationTitle(Text("Key Generator"))
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.newPassword.isLoading)
        .animation(.easeOut, value: viewModel.newlyEnteredPassword.isNotEmpty)
        .task {
            await viewModel.onAppear()
        }
        .onDisappear {
            viewModel.didDisappear()
        }
        .toolbar {
            switch viewModel.newPassword {
            case .initial, .creating, .keygenCancelled, .keygenError, .passwordConfirmError:
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        keyGenerationTask?.cancel()
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .tint(.red)
                    }
                    .disabled(viewModel.newPassword.isLoading)
                }
            case .success:
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                    .disabled(viewModel.newPassword.isLoading)
                }
            }
        }
    }

    private var passwordSection: some View {
        Section {
            FormRow(image: Image(systemName: "lock.fill"), color: .primary, style: .standard) {
                SecureField("New Password", text: $viewModel.newlyEnteredPassword)
            }
            .disabled(viewModel.newPassword.isLoading)

            if viewModel.newlyEnteredPassword.isNotEmpty {
                FormRow(
                    image: Image(
                        systemName: viewModel
                            .passwordConfirmMatches ? "checkmark.circle.fill" : "xmark.circle.fill"
                    ),
                    color: viewModel.passwordConfirmMatches ? .green : .red,
                    style: .standard
                ) {
                    SecureField("Confirm Password", text: $viewModel.newlyEnteredPasswordConfirm)
                }
                .disabled(viewModel.newPassword.isLoading)
            }

        } footer: {
            VStack(alignment: .center, spacing: 8) {
                StandaloneButton {
                    keyGenerationTask?.cancel()
                    keyGenerationTask = Task {
                        await viewModel.saveEnteredPassword()
                    }
                } content: {
                    Text("Generate Key")
                }
                .animation(.none, value: viewModel.newPassword)
                .disabled(!viewModel.canGenerateNewPassword)
                .opacity(viewModel.canGenerateNewPassword ? 1 : 0.5)

                switch viewModel.newPassword {
                case .success:
                    Label("Password and vault encryption key updated successfully", systemImage: "checkmark")
                        .foregroundStyle(.green)
                case .keygenError, .keygenCancelled:
                    Label("Error generating encryption key", systemImage: "questionmark.key.filled")
                        .foregroundStyle(.red)
                case .creating:
                    HStack(alignment: .center, spacing: 4) {
                        ProgressView()
                        Text("Generating encryption key")
                    }
                case .passwordConfirmError:
                    Label("Passwords do not match", systemImage: "xmark")
                        .foregroundStyle(.red)
                case .initial:
                    EmptyView()
                }
            }
            .padding()
            .modifier(HorizontallyCenter())
        }
        .animation(.easeOut, value: viewModel.newlyEnteredPassword)
        .transition(.move(edge: .leading))
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
                Label("Keygen Information", systemImage: "key.horizontal.fill")
            }

            #if DEBUG
            DisclosureGroup {
                Button {
                    viewModel.loadExistingPassword()
                } label: {
                    Text("Fetch existing password")
                }
                VStack(alignment: .leading, spacing: 8) {
                    switch viewModel.existingPassword {
                    case .loading:
                        Text("Loading")
                    case let .hasExistingPassword(backupPassword):
                        Text(backupPassword.key.toHexString())
                            .fontDesign(.monospaced)
                        Text(backupPassword.salt.toHexString())
                            .fontDesign(.monospaced)
                    case .noExistingPassword:
                        Text("None")
                    case .authenticationFailed:
                        Text("Authentication Failed")
                    case .errorFetching:
                        Text("Error")
                    }
                }
            } label: {
                Text("DEBUG: Keygen Information")
            }
            .foregroundStyle(.secondary)
            #endif
        }
    }
}
