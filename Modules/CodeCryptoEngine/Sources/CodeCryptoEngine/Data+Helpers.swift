import Foundation

extension UInt64 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout.size(ofValue: self))
    }
}

extension Data {
    func asType<T>(_: T.Type) -> T {
        withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            ptr.load(as: T.self)
        }
    }
}
