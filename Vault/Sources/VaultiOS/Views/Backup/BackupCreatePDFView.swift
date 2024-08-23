import Foundation
import PDFKit
import SwiftUI
import VaultFeed

@MainActor
struct BackupCreatePDFView: View {
    typealias ViewModel = BackupCreatePDFViewModel
    @State private var viewModel: ViewModel
    @State private var modal: Modal?

    private enum Modal: IdentifiableSelf {
        case pdf(ViewModel.GeneratedPDF)
    }

    init(viewModel: BackupCreatePDFViewModel) {
        _viewModel = .init(initialValue: viewModel)
    }

    var body: some View {
        Form {
            optionsSection
            createSection
        }
        .navigationTitle(Text("Create PDF"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.generatedPDF) { _, newValue in
            if let newValue {
                modal = .pdf(newValue)
            }
        }
        .sheet(item: $modal, onDismiss: nil) { item in
            switch item {
            case let .pdf(generated):
                pdfPreview(generated: generated)
            }
        }
    }

    private func pdfPreview(generated: ViewModel.GeneratedPDF) -> some View {
        NavigationStack {
            PDFViewer(generated.document)
                .navigationTitle(Text("PDF"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(
                            item: generated.diskURL,
                            subject: .init("Vault Export")
                        )
                    }

                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) {
                            modal = nil
                        } label: {
                            Text("Close")
                        }
                    }
                }
        }
    }

    private var optionsSection: some View {
        Section {
            Picker(selection: $viewModel.size) {
                ForEach(ViewModel.Size.allCases) { format in
                    Text(format.localizedTitle)
                        .tag(format)
                }
            } label: {
                FormRow(image: Image(systemName: "newspaper.fill"), color: .accentColor, style: .standard) {
                    Text("Paper Size")
                }
            }

            TextEditor(text: $viewModel.userHint)
                .font(.callout)
                .frame(minHeight: 150)
                .keyboardType(.default)
                .listRowInsets(EdgeInsets(top: 32, leading: 16, bottom: 32, trailing: 16))
        }
    }

    private var createSection: some View {
        Section {
            AsyncButton {
                await viewModel.createPDF()
            } label: {
                FormRow(image: Image(systemName: "checkmark.circle.fill"), color: .accentColor, style: .standard) {
                    Text("Make PDF")
                }
            }
        } footer: {
            if case let .error(presentationError) = viewModel.state {
                Label(
                    presentationError.userDescription ?? presentationError.userTitle,
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.red)
            }
        }
    }
}
