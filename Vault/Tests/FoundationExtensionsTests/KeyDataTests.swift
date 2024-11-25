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

    @Test
    func repeating_createsRepeatingBytes() throws {
        let key = KeyData<Bits256>.repeating(byte: 0x32)

        #expect(key.data.map(\.self) == Array(repeating: 0x32, count: 32))
    }

    @Test
    func zero_createsZeroedKey() throws {
        let zero = KeyData<Bits256>.zero()

        #expect(zero.data.map(\.self) == Array(repeating: 0, count: 32))
    }

    struct Coding {
        @Test
        func encodesToString() throws {
            let encoder = JSONEncoder()
            let key = KeyData<Bits64>.repeating(byte: 0x41)
            let encoded = try encoder.encode(key)
            let str = try #require(String(data: encoded, encoding: .utf8))

            #expect(str == #""QUFBQUFBQUE=""#)
        }

        @Test
        func decodesFromString() throws {
            let encoder = JSONEncoder()
            let key = KeyData<Bits64>.repeating(byte: 0x41)
            let encoded = try encoder.encode(key)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(KeyData<Bits64>.self, from: encoded)

            #expect(decoded == key)
        }
    }

    struct KeyLength {
        @Test
        func bits64() throws {
            #expect(KeyData<Bits64>.random().data.count == 8)
        }

        @Test
        func bits256() throws {
            #expect(KeyData<Bits256>.random().data.count == 32)
        }
    }
}
