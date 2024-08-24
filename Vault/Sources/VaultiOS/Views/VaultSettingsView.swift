import SwiftUI
import VaultFeed
import VaultSettings

@MainActor
struct VaultSettingsView: View {
    @Environment(VaultDataModel.self) private var dataModel
    @Environment(DeviceAuthenticationService.self) private var authenticationService
    @State private var viewModel: SettingsViewModel
    @Bindable private var localSettings: LocalSettings

    @State private var deleteError: PresentationError?

    init(viewModel: SettingsViewModel, localSettings: LocalSettings) {
        _viewModel = State(wrappedValue: viewModel)
        _localSettings = Bindable(wrappedValue: localSettings)
    }

    var body: some View {
        Form {
            viewOptionsSection
            aboutSection
            policySection
            dangerSection
        }
        .navigationTitle(viewModel.title)
    }

    private var viewOptionsSection: some View {
        Section {
            Picker(selection: $localSettings.state.pasteTimeToLive) {
                ForEach(PasteTTL.defaultOptions) { option in
                    Text(option.localizedName)
                        .tag(option)
                }
            } label: {
                FormRow(image: Image(systemName: "clock.fill"), color: .red) {
                    Text(viewModel.pasteTTLTitle)
                }
            }
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView(viewModel: viewModel)
            } label: {
                FormRow(
                    image: Image(systemName: "key.fill"),
                    color: .blue
                ) {
                    Text(viewModel.aboutTitle)
                }
            }

            NavigationLink {
                OpenSourceView()
            } label: {
                FormRow(
                    image: Image(systemName: "figure.2.arms.open"),
                    color: .purple
                ) {
                    Text(viewModel.openSourceTitle)
                }
            }
        }
    }

    private var policySection: some View {
        Section {
            NavigationLink {
                SettingsDocumentView(title: viewModel.termsOfUseTitle, viewModel: TermsOfServiceViewModel())
            } label: {
                FormRow(
                    image: Image(systemName: "person.fill.checkmark"),
                    color: .green
                ) {
                    Text(viewModel.termsOfUseTitle)
                }
            }

            NavigationLink {
                SettingsDocumentView(title: viewModel.privacyPolicyTitle, viewModel: PrivacyPolicyViewModel())
            } label: {
                FormRow(
                    image: Image(systemName: "lock.fill"),
                    color: .red
                ) {
                    Text(viewModel.privacyPolicyTitle)
                }
            }

            NavigationLink {
                ThirdPartyView()
            } label: {
                FormRow(
                    image: Image(systemName: "text.book.closed.fill"),
                    color: .blue
                ) {
                    Text(viewModel.thirdPartyTitle)
                }
            }
        }
    }

    private var dangerSection: some View {
        Section {
            AsyncButton {
                do {
                    withAnimation {
                        deleteError = nil
                    }
                    try await authenticationService.validateAuthentication(reason: "Delete Vault")
                    try await dataModel.deleteVault()
                    try await Task.sleep(for: .seconds(3)) // might be really fast, make it noticable
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
                    image: Image(systemName: "xmark.app.fill"),
                    color: .red,
                    style: .prominent,
                    alignment: desc == nil ? .center : .firstTextBaseline
                ) {
                    TextAndSubtitle(title: "Delete All Data", subtitle: desc)
                }
            }
            .foregroundStyle(.red)
        } header: {
            Label("Danger", systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}
