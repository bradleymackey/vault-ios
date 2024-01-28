import Foundation

/// A shard/block of data from a larger group.
struct DataShard: Equatable, Codable {
    /// Information about the group that this data is part of.
    var group: GroupInfo
    /// The partial data, which should be concatented with all the other blocks in order.
    var data: Data

    enum CodingKeys: String, CodingKey {
        case group = "GROUP"
        case data = "DATA"
    }
}

extension DataShard {
    struct GroupInfo: Equatable, Hashable, Codable, Identifiable {
        /// An ID shared by all of the `SplitDataBlock` instances in this series.
        ///
        /// This ensures we can detect if a block is not in the group.
        var id: UUID
        /// The number that this block is in the group.
        var number: Int
        /// The total number of blocks in the group.
        var totalNumber: Int

        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case number = "NUM"
            case totalNumber = "TOT_NUM"
        }
    }
}
