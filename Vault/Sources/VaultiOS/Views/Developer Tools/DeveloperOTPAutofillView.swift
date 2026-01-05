import AuthenticationServices
import SwiftUI
import Toasts
import VaultFeed

struct DeveloperOTPAutofillView: View {
    @Environment(VaultDataModel.self) var dataModel
    @Environment(\.presentToast) private var presentToast
    @State private var storeState: ASCredentialIdentityStoreState?

    enum Destination: Hashable {
        case addOTPItem
    }

    var body: some View {
        Form {
            Section {
                NavigationLink(value: Destination.addOTPItem) {
                    Text("Add OTP Item")
                }

                AsyncButton {
                    try await dataModel.syncAllToOTPAutofillStore()
                    await loadState()
                    let toast = ToastValue(
                        icon: Image(systemName: "arrow.triangle.2.circlepath"),
                        message: "Synced All Vault Items",
                    )
                    presentToast(toast)
                } label: {
                    Text("Sync All Vault Items")
                } loading: {
                    ProgressView()
                }

                AsyncButton {
                    try await dataModel.clearOTPAutofillStore()
                    await loadState()
                    let toast = ToastValue(icon: Image(systemName: "checkmark"), message: "All OTP Items Cleared")
                    presentToast(toast)
                } label: {
                    Text("Clear All OTP Items")
                } loading: {
                    ProgressView()
                }
                .foregroundStyle(.red)
            } header: {
                Text("Actions")
            }

            Section {
                if let state = storeState {
                    LabeledContent("Extension Enabled") {
                        Image(systemName: state.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(state.isEnabled ? .green : .red)
                    }

                    LabeledContent("Incremental Updates") {
                        Image(systemName: state
                            .supportsIncrementalUpdates ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(state.supportsIncrementalUpdates ? .green : .secondary)
                    }
                } else {
                    Text("Loading state...")
                        .foregroundStyle(.secondary)
                }
            } header: {
                HStack {
                    Text("Current State")
                    Spacer()
                    Button {
                        Task {
                            await loadState()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            } footer: {
                Text(
                    "The credential store state can only be read by the app. Individual credentials are managed by the system and cannot be listed.",
                )
            }
        }
        .navigationTitle("OTP Autofill")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Destination.self) { item in
            switch item {
            case .addOTPItem:
                DeveloperAddOTPItemView()
            }
        }
        .task {
            await loadState()
        }
        .refreshable {
            await loadState()
        }
    }

    private func loadState() async {
        storeState = await dataModel.getOTPAutofillStoreState()
    }
}
