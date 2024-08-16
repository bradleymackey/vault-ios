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

struct VerticallyCenterUpperThird: ViewModifier {
    var alignment: HorizontalAlignment

    func body(content: Content) -> some View {
        VStack(alignment: alignment) {
            Spacer()
            Spacer()
            content
            Spacer()
            Spacer()
            Spacer()
        }
    }
}
