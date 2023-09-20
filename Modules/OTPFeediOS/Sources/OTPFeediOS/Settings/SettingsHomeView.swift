import OTPSettings
import OTPUI
import SwiftUI

public struct SettingsHomeView: View {
    @ObservedObject private var viewModel: SettingsViewModel
    @ObservedObject private var localSettings: LocalSettings

    public init(viewModel: SettingsViewModel, localSettings: LocalSettings) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _localSettings = ObservedObject(wrappedValue: localSettings)
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
                Text("Backup history")
            } label: {
                VStack(alignment: .center) {
                    Text("Last backed up")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                    Text("23 days ago")
                        .foregroundColor(.primary)
                        .font(.title)
                    Text("2 codes not backed up")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }

            NavigationLink {
                Text("Restore")
            } label: {
                FormRow(
                    title: viewModel.restoreBackupTitle,
                    image: Image(systemName: "square.and.arrow.down.fill"),
                    color: .green
                )
            }

            NavigationLink {
                Text("Export")
            } label: {
                FormRow(
                    title: viewModel.saveBackupTitle,
                    image: Image(systemName: "square.and.arrow.up.on.square.fill"),
                    color: .purple
                )
            }
        } header: {
            Text(viewModel.exportOptionsSectionTitle)
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
                Text("Info about Open Source, on GitHub")
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
                Text("Privacy Policy")
            } label: {
                FormRow(
                    title: viewModel.privacyPolicyTitle,
                    image: Image(systemName: "lock.fill"),
                    color: .red
                )
            }

            NavigationLink {
                Text("Terms of Use")
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
