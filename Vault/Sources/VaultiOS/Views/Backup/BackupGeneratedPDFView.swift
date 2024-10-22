import Foundation
import SwiftUI
import VaultFeed

struct BackupGeneratedPDFView: View {
    typealias ViewModel = BackupCreatePDFViewModel
    private let pdf: ViewModel.GeneratedPDF

    init(pdf: ViewModel.GeneratedPDF) {
        self.pdf = pdf
    }

    var body: some View {
        Form {
            pdfPreviewSection
            actionSection
        }
        .navigationTitle(Text("Generated"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pdfPreviewSection: some View {
        Section {
            PDFViewer(pdf.document)
                .listRowInsets(EdgeInsets())
                .frame(minHeight: 200)
                .aspectRatio(pdf.size.aspectRatio, contentMode: .fit)
        }
    }

    private var actionSection: some View {
        Section {
            ShareLink(item: pdf.diskURL, subject: .init("Vault Export")) {
                Text("Export")
            }
        }
    }
}
