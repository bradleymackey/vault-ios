import Foundation

struct ThirdPartyLibraryLoader {
    enum LoadError: Error {
        case invalidResourcePath
    }

    private struct FileStructure: Decodable {
        var libraries: [ThirdPartyLibrary]
    }

    func load() throws -> [ThirdPartyLibrary] {
        guard
            let path = Bundle.module.path(forResource: "third-party-libraries", ofType: "json")
        else {
            throw LoadError.invalidResourcePath
        }
        let url = URL(fileURLWithPath: path)
        let thirdPartyData = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FileStructure.self, from: thirdPartyData)
        return decoded.libraries
    }
}
