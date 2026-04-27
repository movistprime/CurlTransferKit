import XCTest
@testable import CurlTransferKit

final class FTPDirectoryEntryTests: XCTestCase {
    func testParsesUnixFile() {
        let entry = FTPDirectoryEntry(listingLine: "-rw-r--r--   1 root     other        531 Jan 29 03:26 README")

        XCTAssertEqual(entry?.name, "README")
        XCTAssertEqual(entry?.isDirectory, false)
        XCTAssertEqual(entry?.size, 531)
    }

    func testParsesUnixDirectory() {
        let entry = FTPDirectoryEntry(listingLine: "dr-xr-xr-x   2 root     other        512 Apr  8  1994 etc")

        XCTAssertEqual(entry?.name, "etc")
        XCTAssertEqual(entry?.isDirectory, true)
        XCTAssertEqual(entry?.size, 512)
    }

    func testParsesEPLF() {
        let entry = FTPDirectoryEntry(listingLine: "+i8388621.44468,m839956783,r,s10376,\tRFCEPLF")

        XCTAssertEqual(entry?.name, "RFCEPLF")
        XCTAssertEqual(entry?.isDirectory, false)
        XCTAssertEqual(entry?.size, 10376)
    }

    func testReturnsNilForInvalidLine() {
        XCTAssertNil(FTPDirectoryEntry(listingLine: "not an ftp listing"))
    }
}
