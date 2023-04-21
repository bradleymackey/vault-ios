import CryptoEngine
import CryptoExporter
import XCTest

struct BlockIterator: IteratorProtocol {
    func next() -> Data? {
        nil
    }
}

struct BlockExporter: Sequence {
    func makeIterator() -> some IteratorProtocol<Data> {
        BlockIterator()
    }
}

final class BlockExporterTests: XCTestCase {
    func test_init_createsIterator() {
        _ = BlockExporter().makeIterator()
    }
}
