// swiftlint:disable all

import CryptoEngine
import Foundation
import VaultKeygen

// To test this, run:
// `swift run -c release keygen-speedtest`

// Latest results (M1 Pro MacBook Pro - Firestorm Core):
// - RELEASE
//      - Fast = ~0.01s
//      - Secure = ~30s
// - DEBUG
//      - Fast = ~2s
//      - Secure = ???

@main
struct KeygenSpeedtest {
    public static func main() throws {
        print("🚧 Build configuration:", buildConfigString())

        try benchmark(keyDeriver: VaultKeyDeriver.V1.fast, description: "Fast")
        try benchmark(keyDeriver: VaultKeyDeriver.V1.secure, description: "Secure")
    }
}

func benchmark(keyDeriver: some KeyDeriver, description: String) throws {
    print("🚦 Starting '\(description)' derivation")
    let start = Date()
    let key = try keyDeriver.key(password: Data("hello world".utf8), salt: Data("salt".utf8))
    let time = Date().timeIntervalSince(start)
    print("✅ Derived '\(description)' key \(key.data.toHexString()) in \(time)")
}

func buildConfigString() -> String {
    #if DEBUG
    return "⚠️ DEBUG"
    #else
    return "✅ RELEASE"
    #endif
}
