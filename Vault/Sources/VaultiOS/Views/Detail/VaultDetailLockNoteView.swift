import SwiftUI
import VaultFeed

struct VaultDetailLockItemView: View {
    var title: String
    var description: String
    @Binding var lockState: VaultItemLockState

    var body: some View {
        Form {
            titleSection
            optionSection
        }
    }

    private var titleSection: some View {
        Section {
            FormTitleView(
                title: title,
                description: description,
                systemIcon: lockState.isLocked ? "lock.fill" : "lock.open.fill",
                color: .blue
            )
        }
    }

    private var optionSection: some View {
        Section {
            FormRow(
                image: Image(systemName: lockState.isLocked ? "lock.fill" : "lock.open.fill"),
                color: lockState.isLocked ? .red : .green,
                style: .standard,
                alignment: .firstTextBaseline
            ) {
                VStack(alignment: .leading) {
                    Text(lockState.localizedTitle)
                        .font(.body)
                    Text(lockState.localizedSubtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                lockState.isLocked.toggle()
            } label: {
                FormRow(
                    image: Image(systemName: "key.horizontal.fill"),
                    color: .accentColor,
                    style: .standard
                ) {
                    Text(lockState.isLocked ? "Unlock" : "Lock")
                }
            }
        }
    }
}

#Preview {
    VaultDetailLockItemView(title: "Hello", description: "Hello world", lockState: .constant(.lockedWithNativeSecurity))
}
