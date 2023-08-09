import SwiftUI

struct OTPCodeLabels: View {
    var accountName: String
    var issuer: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let issuer {
                Text(issuer)
                    .font(.headline.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Text(accountName)
                .font(issuer != nil ? .footnote : .footnote.weight(.semibold))
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
