import Foundation
import SwiftUI
import VaultFeed

/// View for generating an encryption key while decrypting a backup.
@MainActor
struct BackupKeyDecryptorView: View {
    @State private var viewModel: BackupKeyDecryptorViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: BackupKeyDecryptorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            informationSection
            entrySection
        }
        .navigationTitle(Text("Decrypt Backup"))
        .interactiveDismissDisabled(viewModel.isDecrypting)
        .toolbar {
            if !viewModel.decryptionKeyState.isSuccess {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    .tint(.red)
                    .disabled(viewModel.isDecrypting)
                }
            }
        }
    }

    private var informationSection: some View {
        Section {
            PlaceholderView(
                systemIcon: viewModel.decryptionKeyState.isSuccess ? "lock.open.fill" : "lock.document.fill",
                title: viewModel.decryptionKeyState.title,
                subtitle: viewModel.decryptionKeyState.description
            )
            .padding()
            .containerRelativeFrame(.horizontal)
            .foregroundStyle(viewModel.decryptionKeyState.isError ? .red : .primary)
        }
    }

    private var entrySection: some View {
        Section {
            if viewModel.decryptionKeyState.isSuccess {
                Button {
                    dismiss()
                } label: {
                    FormRow(image: Image(systemName: "play"), color: .accentColor, style: .standard) {
                        Text("Continue")
                    }
                }
            } else {
                FormRow(image: Image(systemName: "lock.fill"), color: .primary, style: .standard) {
                    SecureField("Decryption Password", text: $viewModel.enteredPassword)
                }
                .disabled(viewModel.isDecrypting)

                if viewModel.canAttemptDecryption {
                    AsyncButton {
                        await viewModel.attemptDecryption()
                    } label: {
                        FormRow(
                            image: Image(systemName: "checkmark.circle.fill"),
                            color: .accentColor,
                            style: .standard
                        ) {
                            Text("Decrypt")
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeOut, value: viewModel.canAttemptDecryption)
    }
}
