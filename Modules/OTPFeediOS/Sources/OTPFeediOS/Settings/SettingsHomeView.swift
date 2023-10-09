import OTPSettings
import OTPUI
import SwiftUI

public struct SettingsHomeView: View {
    private var viewModel: SettingsViewModel
    @Bindable private var localSettings: LocalSettings

    public init(viewModel: SettingsViewModel, localSettings: LocalSettings) {
        self.viewModel = viewModel
        _localSettings = Bindable(wrappedValue: localSettings)
    }

    public var body: some View {
        Form {
            viewOptionsSection
            exportSection
            policySection
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var viewOptionsSection: some View {
        Section {
            Picker(selection: $localSettings.state.previewSize) {
                ForEach(PreviewSize.allCases) { previewSize in
                    Text(previewSize.localizedName)
                        .tag(previewSize)
                }
            } label: {
                FormRow(
                    image: Image(systemName: "rectangle.inset.filled"),
                    color: .green
                ) {
                    Text(viewModel.previewSizeTitle)
                }
            }
        }
    }

    private var exportSection: some View {
        Section {
            NavigationLink {
                BackupView()
            } label: {
                VStack(alignment: .center) {
                    Text("Last Backup")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                    Text("23 days ago")
                        .foregroundColor(.primary)
                        .font(.title)
                    Text("iCloud is storing the most recent backup")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                    Text("12 codes backed up")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                    Text("2 codes not yet backed up")
                        .foregroundColor(.red)
                        .font(.footnote.bold())
                }
                .frame(maxWidth: .infinity)
                .padding()
            }

            NavigationLink {
                RestoreBackupView()
            } label: {
                FormRow(
                    image: Image(systemName: "square.and.arrow.down.fill"),
                    color: .blue
                ) {
                    Text(viewModel.restoreBackupTitle)
                }
            }
        }
    }

    private var policySection: some View {
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
                SettingsDocumentView(title: viewModel.termsOfUseTitle, viewModel: TermsOfServiceViewModel())
            } label: {
                FormRow(
                    image: Image(systemName: "person.fill.checkmark"),
                    color: .green
                ) {
                    Text(viewModel.termsOfUseTitle)
                }
            }
        } header: {
            Text(viewModel.policyAndLegacySectionTitle)
        }
    }
}
