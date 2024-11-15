import SwiftUI
import VaultFeed
import VaultSettings

@MainActor
struct VaultSettingsView: View {
    @Environment(VaultDataModel.self) private var dataModel
    @Environment(DeviceAuthenticationService.self) private var authenticationService
    @State private var viewModel: SettingsViewModel
    @Bindable private var localSettings: LocalSettings

    @State private var modal: Modal?

    private enum Modal: IdentifiableSelf {
        case danger
    }

    init(viewModel: SettingsViewModel, localSettings: LocalSettings) {
        _viewModel = State(wrappedValue: viewModel)
        _localSettings = Bindable(wrappedValue: localSettings)
    }

    var body: some View {
        Form {
            headerSection
            aboutSection
            viewOptionsSection
            dangerSection
        }
        .navigationTitle(viewModel.title)
        .sheet(item: $modal, onDismiss: nil) { item in
            switch item {
            case .danger:
                NavigationStack {
                    SettingsDangerView(viewModel: .init(
                        dataModel: dataModel,
                        authenticationService: authenticationService
                    ))
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                modal = nil
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        PlaceholderView(
            systemIcon: "gear",
            title: "Settings",
            subtitle: "Control your Vault settings, customizations, and more."
        )
        .padding()
        .containerRelativeFrame(.horizontal)
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                VaultAboutView(viewModel: viewModel)
            } label: {
                FormRow(
                    image: Image(systemName: "info.bubble.fill"),
                    color: .blue
                ) {
                    Text(viewModel.aboutTitle)
                }
            }
        }
    }

    private var viewOptionsSection: some View {
        Section {
            Picker(selection: $localSettings.state.pasteTimeToLive) {
                ForEach(PasteTTL.defaultOptions) { option in
                    Text(option.localizedName)
                        .tag(option)
                }
            } label: {
                FormRow(image: Image(systemName: "clock.fill"), color: .blue, style: .prominent) {
                    Text(viewModel.pasteTTLTitle)
                }
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Button {
                modal = .danger
            } label: {
                FormRow(
                    image: Image(systemName: "exclamationmark.triangle.fill"),
                    color: .red,
                    style: .prominent
                ) {
                    Text("Danger Zone")
                }
            }
            .tint(.red)
        }
    }
}
