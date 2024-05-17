import SwiftUI
import UIKit
import VaultFeed

extension VaultItemColor {
    init(uiColor: UIColor) {
        guard let ciColor = uiColor.ciColorInRGBColorSpace else {
            self.init(red: 0, green: 0, blue: 0)
            return
        }
        self.init(red: ciColor.red, green: ciColor.green, blue: ciColor.blue)
    }

    init(color: Color) {
        self.init(uiColor: UIColor(color))
    }
}

extension VaultItemColor {
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }

    var color: Color {
        Color(uiColor: uiColor)
    }
}

extension UIColor {
    fileprivate var ciColorInRGBColorSpace: CIColor? {
        // Ensure the UIColor is in the RGB color space
        guard let converted = cgColor
            .converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)
        else {
            return nil
        }
        return CIColor(cgColor: converted)
    }
}
