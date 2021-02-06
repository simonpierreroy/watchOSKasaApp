import XCTest
@testable import WidgetFeature

final class WidgetFeatureTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(WidgetFeature().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
