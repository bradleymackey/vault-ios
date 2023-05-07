import SwiftUI

struct OTPCodeLabels: View {
    var accountName: String
    var issuer: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let issuer {
                Text(issuer)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(accountName)
                .font(.footnote)
                .foregroundColor(issuer != nil ? .secondary : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

struct OTPCodeLabels_Preview: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            OTPCodeLabels(accountName: "test@test.com")
            OTPCodeLabels(accountName: "test@test.com", issuer: "Authority")
        }
    }
}
