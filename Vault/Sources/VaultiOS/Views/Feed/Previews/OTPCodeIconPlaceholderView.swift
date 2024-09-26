import Foundation
import SwiftUI

struct OTPCodeIconPlaceholderView: View {
    let iconFontSize: Double
    var backgroundColor: Color = .gray

    var body: some View {
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

#Preview {
    OTPCodeIconPlaceholderView(iconFontSize: 20)
}
