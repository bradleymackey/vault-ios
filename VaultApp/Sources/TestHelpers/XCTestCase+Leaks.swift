import Foundation
import XCTest

extension XCTestCase {
    public func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance is not dealocated. Potential memory leak", file: file, line: line)
        }
    }
}
