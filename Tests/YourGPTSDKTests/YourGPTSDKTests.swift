import XCTest
@testable import YourGPTSDK

final class YourGPTSDKTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(YourGPTSDK.version, "1.0.0")
    }
}
