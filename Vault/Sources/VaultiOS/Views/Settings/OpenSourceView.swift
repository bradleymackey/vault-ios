import Foundation
import SwiftUI
import VaultSettings

struct OpenSourceView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                container
                    .padding(.vertical, 16)
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
            }
        }
    }

    private var container: some View {
        VStack(alignment: .center, spacing: 24) {
            headerContent
            paragraphContent
        }
    }

    private var headerContent: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "figure.2.arms.open")
                .font(.largeTitle.bold())
            Text(OpenSourceStrings.title)
                .font(.largeTitle.bold())
        }
        .multilineTextAlignment(.center)
    }

    private var paragraphContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(OpenSourceStrings.aboutOpenSource)
            Text(OpenSourceStrings.aboutPrivacy)

            Link(destination: OpenSourceStrings.openSourceLink) {
                Text(OpenSourceStrings.aboutLink)
            }
            .foregroundStyle(.tint)
        }
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.leading)
    }
}

#Preview {
    OpenSourceView()
}
