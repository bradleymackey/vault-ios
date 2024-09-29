import Foundation
import PDFKit

/// @mockable(typealias: Document = DataBlockDocument)
public protocol PDFDocumentRenderer<Document> {
    associatedtype Document
    func render(document: Document) throws -> PDFDocument
}
