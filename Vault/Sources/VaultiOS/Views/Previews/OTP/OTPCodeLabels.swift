import SwiftUI

struct OTPCodeLabels: View {
    var accountName: String
    var issuer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(issuerNameFormatted)
                .font(.headline.bold())
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .truncationMode(.tail)
                .minimumScaleFactor(0.8)
            Text(accountNameFormatted)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }

    private var issuerNameFormatted: String {
        if issuer.isNotEmpty {
            issuer
        } else {
            localized(key: "code.issuerPlaceholder")
        }
    }

    private var accountNameFormatted: String {
        if accountName.isNotEmpty {
            accountName
        } else {
            localized(key: "code.accountNamePlaceholder")
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        OTPCodeLabels(accountName: "", issuer: "")
        OTPCodeLabels(accountName: "test@test.com", issuer: "")
        OTPCodeLabels(accountName: "test@test.com", issuer: "Authority")
    }
}
