import Foundation
import Testing
@testable import FoundationExtensions

struct KeyDataTests {
    @Test(arguments: [0, 1, 21, 31, 33, 100])
    func init_invalidKeyLengthThrows(keyLength: Int) {
        #expect(throws: KeyData<Bits256>.LengthError.self) {
            try KeyData<Bits256>(data: Data(repeating: 0x31, count: keyLength))
        }
    }

    @Test
    func init_validKeyLengthCreatesKey() throws {
        let sut = try KeyData<Bits256>(data: Data(repeating: 0x31, count: 32))

        #expect(sut.data.count == 32)
    }

    @Test(arguments: [
        Data(repeating: 0x31, count: 32),
        Data.random(count: 32),
        Data.random(count: 32),
        Data.random(count: 32),
    ])
    func equatable_sameKeysEqual(data: Data) throws {
        let sut1 = try KeyData<Bits256>(data: data)
        let sut2 = try KeyData<Bits256>(data: data)

        #expect(sut1 == sut2)
    }

    @Test
    func equatable_differentKeysDifferent() throws {
        let sut1 = try KeyData<Bits256>(data: Data(repeating: 0x31, count: 32))
        let sut2 = try KeyData<Bits256>(data: Data(repeating: 0x32, count: 32))

        #expect(sut1 != sut2)
    }

    @Test
    func random_createsRandomKey() throws {
        var seen = Set<KeyData<Bits256>>()
        for _ in 1 ... 100 {
            let key = KeyData<Bits256>.random()
            defer { seen.insert(key) }
            #expect(seen.contains(key) == false)
        }
    }
}
