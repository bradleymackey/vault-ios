import SwiftUI
import UIKit
import VaultFeed

extension VaultItemColor {
    init(uiColor: UIColor) {
        let ciColor = uiColor.ciColor
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
