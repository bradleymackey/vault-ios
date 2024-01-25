import Foundation

/// Draws content to a PDF document.
///
/// If there's no room, it makes a new page and draws there.
struct PDFContentDrawerer {
    /// Try to draw the content. Throw if not possible
    let draw: () -> Result<Void, DrawError>
    /// Make a new page.
    let makeNewPage: () -> Void

    enum DrawError: Error {
        case insufficientSpace
    }

    func drawContent() {
        let result = draw()
        switch result {
        case .success: break
        case .failure:
            makeNewPage()
            // if this fails, we can't draw, even on the next page.
            // there probably just isn't enough space on the page, so ignore.
            // FIXME: should this throw? probably
            _ = draw()
        }
    }
}
