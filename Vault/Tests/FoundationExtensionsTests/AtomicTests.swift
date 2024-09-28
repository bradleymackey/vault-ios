import Foundation
import FoundationExtensions
import Testing

struct AtomicTests {
    @Test(arguments: [1, 2, 3, 100, 12345])
    func init_setsValue(initialValue: Int) {
        let a = Atomic(initialValue: initialValue)

        #expect(a.get { $0 } == initialValue)
    }

    @Test(arguments: [1, 2, 3, 100, 12345])
    func get_getsValueSafely(initialValue: Int) async {
        let a = Atomic(initialValue: initialValue)

        await withDiscardingTaskGroup { group in
            for _ in 0 ... 1000 {
                group.addTask {
                    for _ in 0 ... 100 {
                        #expect(a.get { $0 } == initialValue)
                    }
                }
            }
        }
    }

    @Test(arguments: [1, 2, 3, 100, 12345])
    func value_getsValue(initialValue: Int) async {
        let a = Atomic(initialValue: initialValue)

        #expect(a.value == initialValue)
    }

    @Test(arguments: [1, 2, 3, 100, 12345])
    func modify_modifiesExistingValue(initialValue: Int) async {
        let a = Atomic(initialValue: initialValue)

        a.modify { value in
            value += 2
        }

        #expect(a.get { $0 } == initialValue + 2)
    }

    @Test(arguments: [1, 2, 3, 100, 12345])
    func modify_modifiesValueSafely(initialValue: Int) async {
        let a = Atomic(initialValue: initialValue)

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
