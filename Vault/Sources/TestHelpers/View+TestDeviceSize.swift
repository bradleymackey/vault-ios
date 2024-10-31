import Foundation

#if canImport(SwiftUI)
import SwiftUI

extension View {
    public func framedToTestDeviceSize() -> some View {
        // iPhone 14 size
        frame(width: 390, height: 844)
    }
}

#endif
