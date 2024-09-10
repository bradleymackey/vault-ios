import Foundation
import SwiftUI
import VaultFeed

/// View for generating an encryption key while decrypting a backup.
@MainActor
struct BackupKeyDecryptorView: View {
    @State private var viewModel: BackupKeyDecryptorViewModel

    init(viewModel: BackupKeyDecryptorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            informationSection
            entrySection
        }
        .navigationTitle(Text("Decrypt"))
    }

    private var informationSection: some View {
        Section {
            PlaceholderView(
                systemIcon: viewModel.generated.isSuccess ? "lock.open.fill" : "lock.fill",
                title: viewModel.generated.title,
                subtitle: viewModel.generated.description
            )
            .padding()
            .containerRelativeFrame(.horizontal)
            .foregroundStyle(viewModel.generated.isError ? .red : .primary)
        }
    }

    private var entrySection: some View {
        Section {
            FormRow(image: Image(systemName: "lock.fill"), color: .primary, style: .standard) {
                SecureField("Decryption Password", text: $viewModel.enteredPassword)
            }
            .disabled(viewModel.isDecrypting)

            AsyncButton {
                await viewModel.attemptDecryption()
            } label: {
                FormRow(image: Image(systemName: "checkmark.circle.fill"), color: .accentColor, style: .standard) {
                    Text("Decrypt")
                }
            }
            .disabled(v)
        }
    }
}
