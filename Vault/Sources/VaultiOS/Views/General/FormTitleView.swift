import Foundation
import SwiftUI

struct FormTitleView: View {
    var title: String
    var description: String
    var systemIcon: String
    var color: Color

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HeaderIcon(image: Image(systemName: systemIcon), color: color)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .center, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text(description)
                    .foregroundStyle(.primary)
                    .font(.subheadline)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
}

#Preview {
    Form {
        FormTitleView(
            title: "Hellos",
            description: "This is a description",
            systemIcon: "lock.fill",
            color: .accentColor
        )
    }
}
