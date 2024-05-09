import Foundation
import PDFKit

/// @mockable(typealias: Document = DataBlockDocument; history: render = true)
public protocol PDFDocumentRenderer<Document> {
    associatedtype Document
    func render(document: Document) throws -> PDFDocument
}
