import Foundation
import SwiftUI
import VaultFeed

struct SettingsDangerView: View {
    @Environment(VaultDataModel.self) private var dataModel
    @Environment(DeviceAuthenticationService.self) private var authenticationService
    @State private var deleteError: PresentationError?
    @State private var isDeleting = false

    var body: some View {
        Form {
            headerSection
            actionSection
        }
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(isDeleting)
    }

    private var headerSection: some View {
        Section {
            PlaceholderView(
                systemIcon: "exclamationmark.triangle.fill",
                title: "Danger Zone",
                subtitle: "Be careful what you do here."
            )
            .padding()
            .containerRelativeFrame(.horizontal)
            .foregroundStyle(.red)
        }
    }

    private var actionSection: some View {
        Section {
            AsyncButton {
                do {
                    isDeleting = true
                    defer { isDeleting = false }
                    withAnimation {
                        deleteError = nil
                    }
                    try await authenticationService.validateAuthentication(reason: "Delete Vault")
                    try await dataModel.deleteVault()
                    try await Task.sleep(for: .seconds(2)) // might be really fast, make it noticable
                } catch {
                    withAnimation {
                        deleteError = .init(
                            userTitle: "Can't delete Vault",
                            userDescription: "Unable to delete Vault data right now. Please try again. \(error.localizedDescription)",
                            debugDescription: error.localizedDescription
                        )
                    }
                }
            } label: {
                let desc = deleteError?.userDescription
                FormRow(
                    image: Image(systemName: "trash.fill"),
                    color: .red,
                    style: .standard,
                    alignment: desc == nil ? .center : .firstTextBaseline
                ) {
                    TextAndSubtitle(title: "Delete All Data", subtitle: desc)
                }
            }
            .tint(.red)
        }
    }
}
