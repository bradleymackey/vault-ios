import Foundation
import PDFKit
import Spyable

@Spyable
public protocol PDFDocumentRenderer<Document> {
    associatedtype Document
    func render(document: Document) throws -> PDFDocument
}
