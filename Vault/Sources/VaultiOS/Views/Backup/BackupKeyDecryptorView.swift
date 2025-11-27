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
        .onChange(of: viewModel.decryptionKeyState) { _, newValue in
            if newValue.isSuccess {
                dismiss()
            }
        }
        .toolbar {
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

    private var informationSection: some View {
        Section {
            PlaceholderView(
                systemIcon: "lock.document.fill",
                title: viewModel.decryptionKeyState.title,
                subtitle: viewModel.decryptionKeyState.description,
            )
            .padding()
            .containerRelativeFrame(.horizontal)
            .foregroundStyle(viewModel.decryptionKeyState.isError ? .red : .primary)
        }
    }

    private var entrySection: some View {
        Section {
            FormRow(image: Image(systemName: "lock.fill"), color: .primary, style: .standard) {
                SecureField("Enter decryption password...", text: $viewModel.enteredPassword)
            }
            .disabled(viewModel.isDecrypting)
        } footer: {
            VStack(alignment: .center) {
                AsyncButton {
                    await viewModel.attemptDecryption()
                } label: {
                    Label("Decrypt", systemImage: "checkmark.circle.fill")
                } loading: {
                    ProgressView()
                }
                .modifier(ProminentButtonModifier())
                .transition(.opacity)
                .disabled(!viewModel.canAttemptDecryption || viewModel.isDecrypting)
            }
            .padding()
            .modifier(HorizontallyCenter())
        }
        .animation(.easeOut, value: viewModel.canAttemptDecryption)
    }
}
