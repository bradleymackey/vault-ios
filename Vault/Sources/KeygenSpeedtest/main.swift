// swiftlint:disable all

import CryptoEngine
import Foundation

// To test this, run:
// `swift run -c release KeygenSpeedtest`

// On my M1 Pro MacBook Pro, these paramters take about 20s to resolve.

let parameters = ScryptKeyDeriver.Parameters(
    outputLengthBytes: 32,
    costFactor: 1 << 21,
    blockSizeFactor: 16,
    parallelizationFactor: 1
)
let deriver = try ScryptKeyDeriver(
    password: Data("hello world".utf8),
    salt: Data("salt".utf8),
    parameters: parameters
)
let start = Date()
print("Starting deriving...")
let key = try await deriver.key()
let end = Date()
print("Generated \(key.toHexString()) in \(end.timeIntervalSince1970 - start.timeIntervalSince1970)s")
