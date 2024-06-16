import Foundation
import FoundationExtensions

// For licence formatting:
// https://gchq.github.io/CyberChef/#recipe=Escape_string('Minimal','Double',true,true,false)&input=TGljZW5jZSBoZXJl

/// Things which need attribution.
public struct Attribution: Sendable {
    public var libraries: [ThirdPartyLibrary]

    private init(libraries: [ThirdPartyLibrary]) {
        self.libraries = libraries
    }

    public static func parse(resourceFetcher: any LocalResourceFetcher) async throws -> Attribution {
        let loader = ThirdPartyLibraryLoader(resourceFetcher: resourceFetcher)
        let libraries = try await loader.load()
        return Attribution(libraries: libraries)
    }
}
