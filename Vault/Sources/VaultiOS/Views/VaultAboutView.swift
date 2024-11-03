import Foundation
import SwiftUI
import VaultFeed
import VaultSettings

struct VaultAboutView: View {
    @State private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            headerSection
            helpSection
            tenetsSection
            policySection
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        PlaceholderView(
            systemIcon: "info.bubble.fill",
            title: "Vault",
            subtitle: "Vault has been designed from scratch to store your highly sensitive data that you cannot afford either lose or leak. It's developed in the open and is completely free to use."
        )
        .padding()
        .containerRelativeFrame(.horizontal)
    }

    private var helpSection: some View {
        Section {
            NavigationLink {
                HelpView(viewModel: viewModel)
            } label: {
                FormRow(
                    image: Image(systemName: "questionmark"),
                    color: .blue
                ) {
                    Text(viewModel.helpTitle)
                }
            }
        }
    }

    private var tenetsSection: some View {
        Section {
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
