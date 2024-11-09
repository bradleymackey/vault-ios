import Foundation
import SwiftUI
import VaultFeed

struct VaultDetailEncryptionEditView: View {
    var title: String
    var description: String
    @State private var encryptionIsEnabled: Bool = false

    @State private var newEncryptionPassword = ""
    @State private var newEncryptionPasswordConfirm = ""

    enum EncryptionState {
        case notEncrypted
        case encrypted
    }

    @State private var encryptionState: EncryptionState = .notEncrypted

    var doPasswordsMatch: Bool {
        newEncryptionPassword == newEncryptionPasswordConfirm
    }

    init(
        title: String,
        description: String
    ) {
        self.title = title
        self.description = description
    }

    var body: some View {
        Form {
            titleSection
            switch encryptionState {
            case .notEncrypted:
                createEncryptionSection
            case .encrypted:
                removeEncryptionSection
            }
        }
    }

    private var titleSection: some View {
        Section {
            PlaceholderView(systemIcon: "lock.iphone", title: title, subtitle: description)
                .padding()
                .containerRelativeFrame(.horizontal)
        }
    }

    private var createEncryptionSection: some View {
        Section {
            FormRow(image: Image(systemName: "lock.fill"), color: .primary, style: .standard) {
                SecureField("Password...", text: $newEncryptionPassword)
            }

            if newEncryptionPassword.isNotBlank {
                FormRow(
                    image: Image(
                        systemName: doPasswordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill"
                    ),
                    color: doPasswordsMatch ? .green : .red,
                    style: .standard
                ) {
                    SecureField("Confirm Password", text: $newEncryptionPasswordConfirm)
                }
            }
        } footer: {
            if newEncryptionPassword.isNotBlank {
                Button {
                    encryptionState = .encrypted
                    print("add encryption with password")
                } label: {
                    Label("Encrypt", systemImage: "checkmark.circle.fill")
                }
                .modifier(ProminentButtonModifier())
                .padding()
                .modifier(HorizontallyCenter())
                .disabled(!doPasswordsMatch)
            }
        }
    }

    private var removeEncryptionSection: some View {
        Section {
            FormRow(image: Image(systemName: "checkmark"), color: .primary) {
                Text("Encryption Enabled")
            }
        } footer: {
            Button {
                encryptionState = .notEncrypted
                print("Remove encrpytion from item")
            } label: {
                Label("Remove Encryption", systemImage: "checkmark.circle.fill")
            }
            .modifier(ProminentButtonModifier())
            .padding()
            .modifier(HorizontallyCenter())
            .tint(.red)
        }
    }
}
