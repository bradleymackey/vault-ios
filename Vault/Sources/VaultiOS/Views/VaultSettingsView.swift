import SwiftUI
import VaultFeed
import VaultSettings

@MainActor
public struct VaultSettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Bindable private var localSettings: LocalSettings

    public init(viewModel: SettingsViewModel, localSettings: LocalSettings) {
        _viewModel = State(wrappedValue: viewModel)
        _localSettings = Bindable(wrappedValue: localSettings)
    }

    public var body: some View {
        Form {
            viewOptionsSection
            aboutSection
            policySection
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
}
