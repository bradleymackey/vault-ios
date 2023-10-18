import Foundation

/// Property wrapper that indicates the following variable is stored in a `Defaults` instance.
///
/// Automatically fetches the initial value from storage and sets new values as they are set.
@propertyWrapper
public struct DefaultsStored<T: Codable> {
    private var defaults: Defaults
    private var defaultsKey: Key<T>

    public var wrappedValue: T {
        didSet {
            try? defaults.set(wrappedValue, for: defaultsKey)
        }
    }

    public init(defaults: Defaults, defaultsKey: Key<T>, defaultValue: T) {
        self.defaults = defaults
        self.defaultsKey = defaultsKey
        wrappedValue = defaults.get(for: defaultsKey) ?? defaultValue
    }
}
