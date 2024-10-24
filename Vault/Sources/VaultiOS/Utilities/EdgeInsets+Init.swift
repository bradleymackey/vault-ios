import SwiftUI

extension EdgeInsets {
    init(all: Double) {
        self.init(top: all, leading: all, bottom: all, trailing: all)
    }

    init(vertical: Double = 0, horizontal: Double = 0) {
        self.init(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }
}
