import XCTest
@testable import DeviceFeature

final class DeviceFeatureTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(DeviceFeature().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
