import Foundation
import SwiftUI

extension Color {
    // Calculate brightness of the color
    func brightness() -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        // Use UIColor to get RGB components
        if UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            // Calculate brightness using standard formula
            return 0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue)
        }

        // Default brightness value
        return 0.0
    }

    // Determine appropriate foreground color for contrast
    var contrastingForegroundColor: Color {
        brightness() > 0.9 ? .black : .white
    }
}
