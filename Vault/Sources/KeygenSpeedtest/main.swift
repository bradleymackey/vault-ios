// swiftlint:disable all

import CryptoEngine
import Foundation

// To test this, run:
// `swift run -c release KeygenSpeedtest`

// Latest results (M1 Pro MacBook Pro - Firestorm Core):
// - RELEASE
//      - Fast = ~0.02s
//      - Secure = ~25s
// - DEBUG
//      - Fast = ~10s
//      - Secure = ???

func buildConfigString() -> String {
    #if DEBUG
    return "DEBUG"
    #else
    return "RELEASE"
    #endif
}

print("Running derivation test!")
print("Build configuration:", buildConfigString())

func benchmark(keyDeriver: any KeyDeriver, description: String) throws {
    let start = Date()
    let key = try keyDeriver.key(password: Data("hello world".utf8), salt: Data("salt".utf8))
    let time = Date().timeIntervalSince(start)
    print("Derived '\(description)' key \(key.toHexString()) in \(time)")
}

try benchmark(keyDeriver: CustomKeyDerivers.v1_fast, description: "Fast")
try benchmark(keyDeriver: CustomKeyDerivers.v1_secure, description: "Secure")
