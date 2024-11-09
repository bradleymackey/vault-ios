import Foundation
import SwiftUI
import VaultFeed

struct EncryptedItemDetailView: View {
    @State private var viewModel: EncryptedItemDetailViewModel
    var presentationMode: Binding<PresentationMode>?

    init(item: EncryptedItem, presentationMode: Binding<PresentationMode>? = nil) {
        viewModel = EncryptedItemDetailViewModel(item: item)
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
    }

    private var titleSection: some View {
        Section {
            PlaceholderView(
                systemIcon: "lock.iphone",
                title: "Encrypted",
                subtitle: "A password is required to decrypt this item."
            )
            .padding()
            .containerRelativeFrame(.horizontal)
        }
    }

    private var passwordEntrySection: some View {
        Section {
            FormRow(image: Image(systemName: "lock.fill"), color: .primary, style: .standard) {
                SecureField("Password...", text: $viewModel.enteredEncryptionPassword)
            }
        } footer: {
            Button {
                print("start decryption...")
            } label: {
                Label("Decrypt", systemImage: "key.horizontal.fill")
            }
            .modifier(ProminentButtonModifier())
            .padding()
            .modifier(HorizontallyCenter())
            .disabled(!viewModel.shouldAllowDecryptionToStart)
        }
    }
}
