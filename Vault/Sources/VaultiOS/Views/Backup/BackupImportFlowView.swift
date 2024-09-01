import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct BackupImportFlowView: View {
    @State private var viewModel: BackupImportFlowViewModel
    @State private var isImporting = false
    @State private var importTask: Task<Void, any Error>?

    @Environment(\.dismiss) private var dismiss

    init(viewModel: BackupImportFlowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            switch viewModel.payloadState {
            case .none:
                filePickerSection(isSelected: false)
            case let .error(presentationError):
                filePickerSection(isSelected: true)
                PlaceholderView(
                    systemIcon: "square.and.arrow.down.fill",
                    title: presentationError.userTitle,
                    subtitle: presentationError.userDescription
                )
                .padding()
                .containerRelativeFrame(.horizontal)
                .foregroundStyle(.red)
            case let .ready(vaultApplicationPayload):
                filePickerSection(isSelected: true)
                readyToImportSection(vaultApplicationPayload: vaultApplicationPayload)
            }
        }
        .navigationTitle(Text("Import"))
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(!viewModel.importState.isFinished)
        .animation(.easeOut, value: viewModel.importState)
        .animation(.easeOut, value: viewModel.payloadState)
        .toolbar {
            switch viewModel.importState {
            case .notStarted, .error:
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    .foregroundStyle(.red)
                }
            case .success:
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

    private func filePickerSection(isSelected: Bool) -> some View {
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
            Text(isSelected ? "Select Another Import Option" : "Import Options")
        }
        .transition(.slide)
    }

    private func readyToImportSection(vaultApplicationPayload: VaultApplicationPayload) -> some View {
        Section {
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
        .transition(.slide)
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
