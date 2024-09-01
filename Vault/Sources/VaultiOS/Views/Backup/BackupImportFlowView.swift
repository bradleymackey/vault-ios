import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct BackupImportFlowView: View {
    @State private var viewModel: BackupImportFlowViewModel
    @State private var isImporting = false
    @State private var importTask: Task<Void, any Error>?
    @State private var navPath = NavigationPath()

    @Environment(\.dismiss) private var dismiss

    init(viewModel: BackupImportFlowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            rootForm
        }
        .interactiveDismissDisabled(!viewModel.importState.isFinished)
        .onChange(of: viewModel.payloadState) { _, newValue in
            switch newValue {
            case let .ready(payload, _):
                navPath.append(payload)
            case .none, .error:
                break
            }
        }
    }

    private var rootForm: some View {
        Form {
            switch viewModel.payloadState {
            case .none, .ready:
                filePickerSection()
            case let .error(presentationError):
                Section {
                    PlaceholderView(
                        systemIcon: "exclamationmark.triangle.fill",
                        title: presentationError.userTitle,
                        subtitle: presentationError.userDescription
                    )
                    .padding()
                    .containerRelativeFrame(.horizontal)
                    .foregroundStyle(.red)
                }

                filePickerSection()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .foregroundStyle(.red)
            }
        }
        .animation(.easeOut, value: viewModel.importState)
        .animation(.easeOut, value: viewModel.payloadState)
        .navigationTitle(Text("Import"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: VaultApplicationPayload.self) { payload in
            readyToImportForm(vaultApplicationPayload: payload)
        }
    }

    private func filePickerSection() -> some View {
        Section {
            Button {
                isImporting = true
            } label: {
                FormRow(
                    image: Image(systemName: "externaldrive.fill"),
                    color: .accentColor,
                    style: .standard,
                    alignment: .firstTextBaseline
                ) {
                    TextAndSubtitle(
                        title: "Automatic Import",
                        subtitle: "Select your Vault Export PDF from your files"
                    )
                }
            }
            .foregroundStyle(Color.accentColor)
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.pdf]) { result in
                importTask = Task {
                    await viewModel.handleImport(result: result.tryMap { url in
                        _ = url.startAccessingSecurityScopedResource()
                        defer { url.stopAccessingSecurityScopedResource() }
                        return try Data(contentsOf: url)
                    })
                }
            }

            Button {
                // FIXME: import from camera
            } label: {
                FormRow(
                    image: Image(systemName: "qrcode.viewfinder"),
                    color: .accentColor,
                    style: .standard,
                    alignment: .firstTextBaseline
                ) {
                    TextAndSubtitle(
                        title: "Manual Import",
                        subtitle: "Use your camera to scan all the QR codes on your Vault Export document"
                    )
                }
            }
        } header: {
            Text("Import Options")
        }
    }

    private func readyToImportForm(vaultApplicationPayload: VaultApplicationPayload) -> some View {
        Form {
            switch viewModel.importState {
            case .notStarted:
                PlaceholderView(
                    systemIcon: "square.and.arrow.down.fill",
                    title: viewModel.importContext.readyToImportTitle,
                    subtitle: viewModel.importContext.readyToImportDescription
                )
                .padding()
                .containerRelativeFrame(.horizontal)

                importButton(vault: vaultApplicationPayload)
            case let .error(error):
                PlaceholderView(
                    systemIcon: "exclamationmark.triangle.fill",
                    title: error.userTitle,
                    subtitle: error.userDescription
                )
                .foregroundStyle(.red)
                .padding()
                .containerRelativeFrame(.horizontal)

                importButton(vault: vaultApplicationPayload)
            case .success:
                PlaceholderView(
                    systemIcon: "checkmark.circle.fill",
                    title: "Imported",
                    subtitle: "Your vault has been updated with the items from this backup."
                )
                .foregroundStyle(.green)
                .padding()
                .containerRelativeFrame(.horizontal)
            }
        }
        .animation(.easeOut, value: viewModel.importState)
        .animation(.easeOut, value: viewModel.payloadState)
        .toolbar {
            if viewModel.importState.isFinished {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
    }

    private func importButton(vault: VaultApplicationPayload) -> some View {
        AsyncButton {
            await viewModel.importPayload(payload: vault)
        } label: {
            FormRow(image: Image(systemName: "checkmark.circle.fill"), color: .accentColor, style: .standard) {
                Text("Import Now")
            }
        }
    }
}
