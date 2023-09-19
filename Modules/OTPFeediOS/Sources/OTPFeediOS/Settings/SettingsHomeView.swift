import OTPSettings
import OTPUI
import SwiftUI

public struct SettingsHomeView: View {
    @ObservedObject private var localSettings: LocalSettings

    public init(localSettings: LocalSettings) {
        _localSettings = ObservedObject(wrappedValue: localSettings)
    }

    public var body: some View {
        Form {
            viewOptionsSection
            exportSection
            policySection
        }
        .navigationTitle(localizedSettings(key: "home.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var viewOptionsSection: some View {
        Section {
            Picker(selection: $localSettings.state.previewSize) {
                ForEach(PreviewSize.allCases) { previewSize in
                    Text(previewSize.rawValue)
                        .tag(previewSize)
                }
            } label: {
                FormRow(
                    title: localizedSettings(key: "viewOptions.previewSize.title"),
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
                    title: localizedSettings(key: "restoreBackup.title"),
                    image: Image(systemName: "square.and.arrow.down.fill"),
                    color: .green
                )
            }

            NavigationLink {
                Text("Export")
            } label: {
                FormRow(
                    title: localizedSettings(key: "saveBackup.title"),
                    image: Image(systemName: "square.and.arrow.up.on.square.fill"),
                    color: .purple
                )
            }
        } header: {
            Text(localizedSettings(key: "home.header.export.title"))
        }
    }

    private var policySection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                FormRow(
                    title: localizedSettings(key: "about.title"),
                    image: Image(systemName: "key.fill"),
                    color: .blue
                )
            }

            NavigationLink {
                Text("Info about Open Source, on GitHub")
            } label: {
                FormRow(
                    title: localizedSettings(key: "openSource.title"),
                    image: Image(systemName: "figure.2.arms.open"),
                    color: .purple
                )
            }

            NavigationLink {
                ThirdPartyView()
            } label: {
                FormRow(
                    title: localizedSettings(key: "thirdPartyLibraries.title"),
                    image: Image(systemName: "text.book.closed.fill"),
                    color: .blue
                )
            }

            NavigationLink {
                Text("Privacy Policy")
            } label: {
                FormRow(
                    title: localizedSettings(key: "privacyPolicy.title"),
                    image: Image(systemName: "lock.fill"),
                    color: .red
                )
            }

            NavigationLink {
                Text("Terms of Use")
            } label: {
                FormRow(
                    title: localizedSettings(key: "termsOfUse.title"),
                    image: Image(systemName: "person.fill.checkmark"),
                    color: .green
                )
            }
        } header: {
            Text(localizedSettings(key: "home.header.policyAndLegal.title"))
        }
    }
}
