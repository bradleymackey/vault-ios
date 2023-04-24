import Foundation
import PDFKit

public protocol PDFDocumentRenderer<Document> {
    associatedtype Document
    func render(document: Document) -> PDFDocument?
}
