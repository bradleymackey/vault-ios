import Foundation
import SwiftUI

public struct OpenSourceView: View {
    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                container
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
            Text("Open Source")
                .font(.largeTitle.bold())
        }
    }

    private var paragraphContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Please view the source code for this project")
            Text(
                "When it comes to storing your senstive data, never take anyone at their word. You can audit the source code and build this app yourself if you desire."
            )
        }
        .multilineTextAlignment(.leading)
    }
}
