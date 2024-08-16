import Foundation

/// A shard/block of data from a larger group.
struct DataShard: Equatable, Codable {
    /// Information about the group that this data is part of.
    var group: GroupInfo
    /// The partial data, which should be concatented with all the other blocks in order.
    var data: Data

    enum CodingKeys: String, CodingKey {
        case group = "G"
        case data = "D"
    }
}

extension DataShard {
    struct GroupInfo: Equatable, Hashable, Codable, Identifiable {
        /// An ID shared by all of the `SplitDataBlock` instances in this series.
        ///
        /// This ensures we can detect if a block is not in the group.
        /// It doesn't need to be globally unique, just roughly unique to each individual user.
        var id: UInt16
        /// The number that this block is in the group.
        var number: Int
        /// The total number of blocks in the group.
        var totalNumber: Int

        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case number = "I"
            case totalNumber = "N"
        }
    }
}
