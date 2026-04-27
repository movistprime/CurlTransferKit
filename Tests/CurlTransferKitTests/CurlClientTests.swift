import XCTest
@testable import CurlTransferKit

final class CurlClientTests: XCTestCase {
    func testCreatesClient() {
        _ = CurlClient(urlString: "http://localhost")
    }
}
