import Attribution
import SwiftUI

public struct ThirdPartyView: View {
    @State private var libraries = [ThirdPartyLibrary]()
    public init() {}

    public var body: some View {
        List(libraries) { library in
            Text(library.name)
        }
        .task {
            do {
                let attribution = try Attribution.parse()
                libraries = attribution.libraries
            } catch {
                // TODO: handle
            }
        }
    }
}
