import SwiftUI

struct OTPCodeLabels: View {
    var accountName: String
    var issuer: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(issuerNameFormatted)
                .font(.headline.bold())
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .truncationMode(.tail)
                .minimumScaleFactor(0.8)
            Text(accountNameFormatted)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }

    private var issuerNameFormatted: String {
        issuer ?? localized(key: "code.issuerPlaceholder")
    }

    private var accountNameFormatted: String {
        if accountName.isEmpty {
            localized(key: "code.accountNamePlaceholder")
        } else {
            accountName
        }
    }
}

struct OTPCodeLabels_Preview: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            OTPCodeLabels(accountName: "")
            OTPCodeLabels(accountName: "test@test.com")
            OTPCodeLabels(accountName: "test@test.com", issuer: "Authority")
        }
    }
}
