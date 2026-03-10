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
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                switch viewModel.permissionState {
                case .undetermined:
                    authenticateCard(isError: false)
                case .allowed:
                    warningCard
                    passwordCard
                    detailsCard
                case .denied:
                    authenticateCard(isError: true)
                }
            }
            .padding(16)
        }
        .navigationTitle(Text("Backup Password"))
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

    // MARK: - Authenticate Card

    private func authenticateCard(isError: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            PlaceholderView(
                systemIcon: isError ? "key.slash.fill" : "lock.fill",
                title: isError ? "Authentication Failed" : "Locked",
                subtitle: isError ? "Unable to verify your identity. Please try again."
                    : "Authenticate to change the backup password.",
            )

            AsyncButton(progressAlignment: .center) {
                await viewModel.onAppear()
            } label: {
                Label("Authenticate", systemImage: "key.horizontal.fill")
                    .frame(maxWidth: .infinity)
            } loading: {
                ProgressView()
                    .tint(.white)
            }
            .modifier(ProminentButtonModifier())
        }
        .padding(16)
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: isError ? .red : .accentColor,
            padding: .init(),
        )))
    }

    // MARK: - Warning Card

    private var warningCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 40, height: 40)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Historical Backups")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    Text(
                        "Changing your password will not update existing backups. To restore from a previous backup, you must use the password that was active when that backup was created.",
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: .orange,
            padding: .init(),
        )))
    }

    // MARK: - Password Card

    private var passwordCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "key.horizontal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("New Password")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    Text("Enter a new password to generate an encryption key.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(16)

            Divider()
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.primary)

                    SecureField("New Password", text: $viewModel.newlyEnteredPassword)
                }
                .disabled(viewModel.newPassword.isLoading)

                if viewModel.newlyEnteredPassword.isNotEmpty {
                    HStack(spacing: 12) {
                        Image(
                            systemName: viewModel
                                .passwordConfirmMatches ? "checkmark.circle.fill" : "xmark.circle.fill",
                        )
                        .frame(width: 28, height: 28)
                        .foregroundStyle(viewModel.passwordConfirmMatches ? .green : .red)

                        SecureField("Confirm Password", text: $viewModel.newlyEnteredPasswordConfirm)
                    }
                    .disabled(viewModel.newPassword.isLoading)
                }
            }
            .padding(16)

            Divider()
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                Button {
                    keyGenerationTask?.cancel()
                    keyGenerationTask = Task {
                        await viewModel.saveEnteredPassword()
                    }
                } label: {
                    Label("Generate Key", systemImage: "key.2.on.ring.fill")
                        .frame(maxWidth: .infinity)
                }
                .modifier(ProminentButtonModifier())
                .animation(.none, value: viewModel.newPassword)
                .disabled(!viewModel.canGenerateNewPassword)
                .opacity(viewModel.canGenerateNewPassword ? 1 : 0.5)

                Group {
                    switch viewModel.newPassword {
                    case .success:
                        Label("Vault encryption key updated successfully", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    case .keygenError, .keygenCancelled:
                        Label("Error generating encryption key", systemImage: "xmark.octagon.fill")
                            .foregroundStyle(.red)
                    case .creating:
                        HStack(alignment: .center, spacing: 4) {
                            ProgressView()
                            Text("Generating encryption key")
                        }
                        .foregroundStyle(.secondary)
                    case .passwordConfirmError:
                        Label("Passwords do not match", systemImage: "xmark")
                            .foregroundStyle(.red)
                    case .initial:
                        EmptyView()
                    }
                }
                .font(.caption)
            }
            .padding(16)
        }
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: Color.accentColor,
            padding: .init(),
        )))
        .animation(.easeOut, value: viewModel.newlyEnteredPassword)
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.gray)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Details")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    Text("Encryption algorithm and key generation info.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(16)

            Divider()
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 16) {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your password is used to generate an encryption key that is used to secure your vault.")
                        Text(
                            "For security, this key generation process may take up to 3 minutes, even on a very fast device.",
                        )
                        Text(
                            "Your encryption key is not shared between devices.",
                        )
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                } label: {
                    Label("About", systemImage: "questionmark.circle.fill")
                }

                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 8) {
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
                    }
                } label: {
                    Label("Keygen Information", systemImage: "key.horizontal.fill")
                }

                #if DEBUG
                DisclosureGroup {
                    AsyncButton {
                        await viewModel.loadExistingPassword()
                    } label: {
                        Text("Fetch existing password")
                    } loading: {
                        ProgressView()
                    }
                } label: {
                    Text("DEBUG: Keygen Information")
                }
                .foregroundStyle(.secondary)
                #endif
            }
            .padding(16)
        }
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: .gray,
            padding: .init(),
        )))
    }
}
