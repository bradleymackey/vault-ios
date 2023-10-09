import OTPSettings
import OTPUI
import SwiftUI

public struct SettingsHomeView: View {
    @ObservedObject private var viewModel: SettingsViewModel
    @Bindable private var localSettings: LocalSettings

    public init(viewModel: SettingsViewModel, localSettings: LocalSettings) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
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
                    title: viewModel.previewSizeTitle,
                    image: Image(systemName: "rectangle.inset.filled"),
                    color: .green
                )
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
                    title: viewModel.restoreBackupTitle,
                    image: Image(systemName: "square.and.arrow.down.fill"),
                    color: .blue
                )
            }
        }
    }

    private var policySection: some View {
        Section {
            NavigationLink {
                AboutView(viewModel: viewModel)
            } label: {
                FormRow(
                    title: viewModel.aboutTitle,
                    image: Image(systemName: "key.fill"),
                    color: .blue
                )
            }

            NavigationLink {
                OpenSourceView()
            } label: {
                FormRow(
                    title: viewModel.openSourceTitle,
                    image: Image(systemName: "figure.2.arms.open"),
                    color: .purple
                )
            }

            NavigationLink {
                ThirdPartyView()
            } label: {
                FormRow(
                    title: viewModel.thirdPartyTitle,
                    image: Image(systemName: "text.book.closed.fill"),
                    color: .blue
                )
            }

            NavigationLink {
                SettingsDocumentView(title: viewModel.privacyPolicyTitle, viewModel: PrivacyPolicyViewModel())
            } label: {
                FormRow(
                    title: viewModel.privacyPolicyTitle,
                    image: Image(systemName: "lock.fill"),
                    color: .red
                )
            }

            NavigationLink {
                SettingsDocumentView(title: viewModel.termsOfUseTitle, viewModel: TermsOfServiceViewModel())
            } label: {
                FormRow(
                    title: viewModel.termsOfUseTitle,
                    image: Image(systemName: "person.fill.checkmark"),
                    color: .green
                )
            }
        } header: {
            Text(viewModel.policyAndLegacySectionTitle)
        }
    }
}
