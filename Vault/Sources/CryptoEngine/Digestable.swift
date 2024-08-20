import Foundation

/// This type can be used to create a digest/hash.
///
/// This is achieved for
public protocol Digestable {
    associatedtype Digest: Encodable
    var digestableData: Digest { get }
}
