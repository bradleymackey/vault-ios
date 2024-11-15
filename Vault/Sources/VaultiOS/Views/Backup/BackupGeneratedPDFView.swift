import Foundation
import SwiftUI
import VaultFeed

struct BackupGeneratedPDFView: View {
    typealias ViewModel = BackupCreatePDFViewModel
    private let pdf: ViewModel.GeneratedPDF
    private let dismiss: () -> Void

    @Environment(\.displayScale) private var displayScale

    private let previewTargetWidth = 80.0

    init(pdf: ViewModel.GeneratedPDF, dismiss: @escaping () -> Void) {
        self.pdf = pdf
        self.dismiss = dismiss
    }

    var body: some View {
        Form {
            pdfPreviewSection
        }
        .navigationTitle(Text("PDF"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .interactiveDismissDisabled()
        .navigationBarBackButtonHidden()
    }

    private var pdfPreviewSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 16) {
                    Spacer(minLength: 2)
                    ForEach(0 ..< pdf.document.pageCount, id: \.self) { pageIndex in
                        thumbnail(pageIndex: pageIndex)?
                            .resizable(resizingMode: .stretch)
                            .aspectRatio(pdf.size.aspectRatio, contentMode: .fit)
                            .frame(width: previewTargetWidth)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .shadow(radius: 5)
                    }
                    Spacer(minLength: 2)
                }
                .padding(.vertical, 16)
            }
            .listRowInsets(EdgeInsets())
        } header: {
            Text("Generated Document Preview")
        } footer: {
            VStack(alignment: .center, spacing: 8) {
                exportButton

                Label(
                    "Make sure you export and save the PDF, or your data will not be backed up.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.red)
                .font(.footnote)
                .multilineTextAlignment(.center)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
    }

    private var exportButton: some View {
        ShareLink(item: pdf.diskURL, subject: .init("Vault Export")) {
            Label("Export & Save", systemImage: "square.and.arrow.up.fill")
        }
        .modifier(ProminentButtonModifier())
    }

    private func thumbnail(pageIndex: Int) -> Image? {
        let pageAspectRatio = pdf.size.aspectRatio
        let devicePreviewSize = displayScale * previewTargetWidth
        let scaledSize = CGSize(width: devicePreviewSize, height: devicePreviewSize / pageAspectRatio)
        let page = pdf.document.page(at: pageIndex)
        guard let uiimage = page?.thumbnail(of: scaledSize, for: .trimBox) else { return nil }
        return Image(uiImage: uiimage)
    }
}
