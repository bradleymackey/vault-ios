import Foundation

#if canImport(SwiftUI)
import SwiftUI

extension View {
    /// Fixed width at the test device size, height whatever the content wants.
    ///
    /// - parameter height: the height to make the view (defaults to 1000pts)
    public func framedForTest(height: CGFloat = 1000) -> some View {
        // iPhone 14 width
        frame(width: 390, height: height)
    }
}

#endif
