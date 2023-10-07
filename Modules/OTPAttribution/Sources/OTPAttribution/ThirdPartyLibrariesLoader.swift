import Foundation
import FoundationExtensions

struct ThirdPartyLibraryLoader {
    private struct FileStructure: Decodable {
        var libraries: [ThirdPartyLibrary]
    }

    private let resourceFetcher: LocalResourceFetcher

    init(resourceFetcher: LocalResourceFetcher) {
        self.resourceFetcher = resourceFetcher
    }

    func load() throws -> [ThirdPartyLibrary] {
        let thirdPartyData = try resourceFetcher.fetchLocalResource(
            fromBundle: .module,
            fileName: "third-party-libraries",
            fileExtension: "json"
        )
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FileStructure.self, from: thirdPartyData)
        return decoded.libraries
    }
}
