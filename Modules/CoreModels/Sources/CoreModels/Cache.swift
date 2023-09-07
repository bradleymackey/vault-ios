public struct Cache<Key: Hashable, Value> {
    private var cacheStorage = [Key: Value]()

    public init() {}

    public subscript(key: Key) -> Value? {
        cacheStorage[key]
    }

    public var count: Int {
        cacheStorage.count
    }

    public mutating func removeAll() {
        cacheStorage.removeAll()
    }

    /// Get a given item from the cache, otherwise create it using the
    /// given closure.
    public mutating func get(key: Key, otherwise generate: () throws -> Value) rethrows -> Value {
        if let existing = cacheStorage[key] {
            return existing
        } else {
            let created = try generate()
            cacheStorage[key] = created
            return created
        }
    }

    /// Removes the item with this key from the cache.
    public mutating func remove(key: Key) {
        cacheStorage[key] = nil
    }
}
