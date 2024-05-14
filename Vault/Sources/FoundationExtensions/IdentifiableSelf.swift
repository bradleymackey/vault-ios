public protocol IdentifiableSelf: Identifiable where Self: Hashable {}

extension IdentifiableSelf {
    public var id: Self { self }
}
