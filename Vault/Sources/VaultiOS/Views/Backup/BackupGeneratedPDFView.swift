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
        PDFViewer(pdf.document)
            .navigationTitle(Text("PDF"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(
                        item: pdf.diskURL,
                        subject: .init("Vault Export")
                    )
                }
            }
    }
}
