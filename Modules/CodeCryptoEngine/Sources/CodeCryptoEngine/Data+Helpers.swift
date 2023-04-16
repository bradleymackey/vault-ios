import Foundation

extension UInt64 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout.size(ofValue: self))
    }
}

extension Data {
    /// An unsafe operation to cast the bytes of this data to the provided type.
    func asType<T>(_: T.Type) -> T {
        withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            ptr.load(as: T.self)
        }
    }

    /// Interpret the UTF-8 bytes of the provided string as data.
    public init(byteString: String) {
        self.init(byteString.utf8)
    }
}
