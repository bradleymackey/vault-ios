import Foundation
import SwiftUI
import VaultFeed

struct EncryptedItemDetailView: View {
    @State private var viewModel: EncryptedItemDetailViewModel
    var presentationMode: Binding<PresentationMode>?

    init(viewModel: EncryptedItemDetailViewModel, presentationMode: Binding<PresentationMode>? = nil) {
        self.viewModel = viewModel
        self.presentationMode = presentationMode
    }

    private func dismiss() {
        presentationMode?.wrappedValue.dismiss()
    }

    var body: some View {
        Form {
            titleSection
            passwordEntrySection
        }
        .navigationTitle("Item")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.state) { _, newValue in
            switch newValue {
            case let .decrypted(item):
                // TODO: send item detail so parent knows to present it
                dismiss()
            default:
                break
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
            }
        }
    }

    private var titleSection: some View {
        Section {
            if let error = viewModel.state.presentationError {
                PlaceholderView(
                    systemIcon: "exclamationmark.triangle.fill",
                    title: error.userTitle,
                    subtitle: error.userDescription
                )
                .padding()
                .containerRelativeFrame(.horizontal)
                .foregroundStyle(.red)
            } else {
                PlaceholderView(
                    systemIcon: "lock.iphone",
                    title: "Encrypted",
                    subtitle: "A password is required to decrypt this item."
                )
                .padding()
                .containerRelativeFrame(.horizontal)
            }
        }
    }

    private var passwordEntrySection: some View {
        Section {
            FormRow(image: Image(systemName: "lock.fill"), color: .primary, style: .standard) {
                SecureField("Password...", text: $viewModel.enteredEncryptionPassword)
            }
        } footer: {
            AsyncButton {
                await viewModel.startDecryption()
            } label: {
                Label("Decrypt", systemImage: "key.horizontal.fill")
            }
            .modifier(ProminentButtonModifier())
            .padding()
            .modifier(HorizontallyCenter())
            .disabled(!viewModel.canStartDecryption)
        }
        .onChange(of: viewModel.enteredEncryptionPassword) { _, _ in
            // When the text changes, reset the state.
            viewModel.resetState()
        }
    }
}
