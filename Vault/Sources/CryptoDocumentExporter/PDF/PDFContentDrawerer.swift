import Foundation

/// Draws content to a PDF document.
///
/// If there's no room, it makes a new page and draws there.
struct PDFContentDrawerer {
    /// Try to draw the content. Throw if not possible
    let draw: () -> Result<DrawSuccess, DrawError>
    /// Make a new page.
    let makeNewPage: () -> Void

    enum DrawSuccess {
        case didDrawToDocument
    }

    enum DrawError: Error {
        /// There is no space to draw on the current page.
        case insufficientSpace
        /// There's content missing, just ignore this item as we have nothing to draw.
        case contentMissing
    }

    func drawContent() {
        let result = draw()
        switch result {
        case .success:
            // draw is complete, nothing more to do
            break
        case .failure(.insufficientSpace):
            makeNewPage()
            // if this fails, we can't draw, even on the next page.
            // there probably just isn't enough space on the page, so ignore.
            // FIXME: should this throw? probably
            _ = draw()
        case .failure(.contentMissing):
            // there is no content to draw, just ignore
            break
        }
    }
}
