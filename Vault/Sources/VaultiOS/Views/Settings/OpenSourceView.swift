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
            Text(OpenSourceViewModel.title)
                .font(.largeTitle.bold())
        }
        .multilineTextAlignment(.center)
    }

    private var paragraphContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(OpenSourceViewModel.aboutOpenSource)
            Text(OpenSourceViewModel.aboutPrivacy)

            Link(destination: URL(string: "https://google.com")!) {
                Text(OpenSourceViewModel.aboutLink)
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
