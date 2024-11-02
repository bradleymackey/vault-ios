import SwiftUI
import VaultFeed

struct VaultDetailLockEditView: View {
    var title: String
    var description: String
    @Binding var lockState: VaultItemLockState

    var body: some View {
        Form {
            titleSection
        }
    }

    private var titleSection: some View {
        Section {
            PlaceholderView(
                systemIcon: lockState.isLocked ? "lock.fill" : "lock.open.fill",
                title: title,
                subtitle: description
            )
            .padding()
            .containerRelativeFrame(.horizontal)

            Toggle(isOn: $lockState.isLocked) {
                FormRow(
                    image: Image(systemName: lockState.isLocked ? "checkmark.circle.fill" : "xmark.circle.fill"),
                    color: lockState.isLocked ? .green : .secondary,
                    style: .standard
                ) {
                    Text("Lock item")
                        .font(.body)
                }
            }
        } footer: {
            Text(lockState.localizedSubtitle)
        }
    }
}

#Preview {
    VaultDetailLockEditView(title: "Hello", description: "Hello world", lockState: .constant(.lockedWithNativeSecurity))
}
