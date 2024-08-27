import Foundation

extension Result where Failure == any Error {
    public func tryMap<NewSuccess>(_ transform: (Success) throws -> NewSuccess) -> Result<NewSuccess, any Error> {
        flatMap { value in
            Result<NewSuccess, any Error> { try transform(value) }
        }
    }
}
