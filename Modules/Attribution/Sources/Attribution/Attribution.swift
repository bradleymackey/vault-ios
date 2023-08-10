import Foundation

// For licence formatting:
// https://gchq.github.io/CyberChef/#recipe=Escape_string('Minimal','Double',true,true,false)&input=TGljZW5jZSBoZXJl

/// Things which need attribution.
public struct Attribution {
    public var libraries: [ThirdPartyLibrary]

    private init(libraries: [ThirdPartyLibrary]) {
        self.libraries = libraries
    }

    public static func parse() throws -> Attribution {
        try Attribution(
            libraries: ThirdPartyLibraryLoader().load()
        )
    }
}
