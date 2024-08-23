import Foundation
import FoundationExtensions
import XCTest

final class AtomicTests: XCTestCase {
    func test_init_setsValue() {
        let a = Atomic(initialValue: 100)

        XCTAssertEqual(a.get { $0 }, 100)
    }

    func test_get_getsValueSafely() async {
        let a = Atomic(initialValue: 100)

        await withDiscardingTaskGroup { group in
            for _ in 0 ... 1000 {
                group.addTask {
                    for _ in 0 ... 100 {
                        let n = a.get { $0 }
                        XCTAssertEqual(n, 100)
                    }
                }
            }
        }
    }

    func test_modify_modifiesValueSafely() async {
        let a = Atomic(initialValue: 100)

        await withDiscardingTaskGroup { group in
            for i in 0 ... 1000 {
                group.addTask {
                    for j in 0 ... 100 {
                        a.modify { $0 = 2 * i + 3 * j }
                    }
                }
            }
        }
    }
}
