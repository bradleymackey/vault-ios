import Foundation

extension Data {
    static func random(count: Int) -> Data {
        var bytes = [UInt8]()
        bytes.reserveCapacity(count)
        for _ in 0 ..< count {
            let nextByte = UInt8.random(in: UInt8.min ... UInt8.max)
            bytes.append(nextByte)
        }
        return Data(bytes)
    }
}
