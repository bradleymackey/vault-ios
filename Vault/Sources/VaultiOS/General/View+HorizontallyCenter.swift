import Foundation
import SwiftUI

struct HorizontallyCenter: ViewModifier {
    func body(content: Content) -> some View {
        HStack(alignment: .center) {
            Spacer()
            content
            Spacer()
        }
    }
}
