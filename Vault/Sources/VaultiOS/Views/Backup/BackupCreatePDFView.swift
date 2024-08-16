import Foundation
import FoundationExtensions
import PDFKit
import SwiftUI
import VaultFeed

struct BackupCreatePDFView: View {
    @State private var viewModel: BackupCreatePDFViewModel
    @State private var modal: Modal?

    private enum Modal: IdentifiableSelf {
        case pdf(PDFDocument)
    }

    init(viewModel: BackupCreatePDFViewModel) {
        _viewModel = .init(initialValue: viewModel)
    }

    var body: some View {
        Form {
            switch viewModel.state {
            case .idle:
                EmptyView()
            case .loading:
                ProgressView()
            case let .error(presentationError):
                Text(presentationError.debugDescription)
            case .success:
                Text("Success")
            }
            Button {
                Task {
                    await viewModel.createPDF()
                }
            } label: {
                Text("Make PDF")
            }
        }
        .navigationTitle(Text("Create PDF"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.createdDocument) { _, newValue in
            if let newValue {
                modal = .pdf(newValue)
            }
        }
        .sheet(item: $modal, onDismiss: nil) { item in
            switch item {
            case let .pdf(document):
                PDFViewer(document)
            }
        }
    }
}
