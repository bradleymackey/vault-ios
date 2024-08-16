import Foundation

struct DataShardBuilder {
    /// Max size of a QR code is actually 2953 bytes, but let's leave some headroom so the codes are not too compact.
    /// We want to avoid the codes being too compact because it makes it harder to scan them.
    private let maxDataBlockSize = 500
    private let groupIDGenerator: () -> UInt16

    init(groupIDGenerator: @escaping () -> UInt16 = { .random(in: UInt16.min ..< UInt16.max) }) {
        self.groupIDGenerator = groupIDGenerator
    }

    func makeShards(from data: Data) -> [DataShard] {
        let groupID = groupIDGenerator()
        let content = data.bytes.chunked(into: maxDataBlockSize).map { Data($0) }

        if content.isEmpty {
            return [
                DataShard(
                    group: .init(
                        id: groupID,
                        number: 0,
                        totalNumber: 1
                    ),
                    data: Data()
                ),
            ]
        } else {
            let blocksRequired = content.count
            return content.enumerated().map { chunkIndex, chunkData in
                DataShard(
                    group: .init(
                        id: groupID,
                        number: chunkIndex,
                        totalNumber: blocksRequired
                    ),
                    data: chunkData
                )
            }
        }
    }
}

extension Array {
    fileprivate func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
