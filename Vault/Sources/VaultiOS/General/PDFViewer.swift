import PDFKit
import SwiftUI

/// Displays `PDFDocument` from `PDFKit` in SwiftUI.
struct PDFViewer: UIViewRepresentable {
    typealias UIViewType = PDFView

    let document: PDFDocument

    init(_ document: PDFDocument) {
        self.document = document
    }

    func makeUIView(context _: UIViewRepresentableContext<Self>) -> UIViewType {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        return pdfView
    }

    func updateUIView(_ pdfView: UIViewType, context _: UIViewRepresentableContext<Self>) {
        pdfView.document = document
    }
}
