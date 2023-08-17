import Foundation
import SwiftUI

public struct OTPCardViewModifier: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content
            .padding(8)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct OTPCardViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        Text("Testing")
            .modifier(OTPCardViewModifier())
    }
}
