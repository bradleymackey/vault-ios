import Foundation
import SwiftUI

public struct OTPCodeIconPlaceholderView: View {
    public let iconFontSize: Double
    public var backgroundColor: Color = .gray

    public var body: some View {
        ZStack(alignment: .center) {
            backgroundColor
            Image(systemName: "key.horizontal.fill")
                .foregroundColor(.white)
                .font(.system(size: iconFontSize))
        }
        .frame(width: size, height: size)
    }

    private var size: Double {
        iconFontSize * 2
    }
}

struct OTPCodeIconPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        OTPCodeIconPlaceholderView(iconFontSize: 20)
    }
}
