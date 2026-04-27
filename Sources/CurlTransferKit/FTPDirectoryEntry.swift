import CCurlTransferKit
import Foundation

public struct FTPDirectoryEntry: Equatable {
    public let name: String
    public let isDirectory: Bool
    public let size: Int64

    public init?(listingLine: String) {
        var parsedName: NSString?
        var parsedIsDirectory = ObjCBool(false)
        var parsedSize: Int64 = 0

        guard CCTKParseFTPDirectoryEntry(listingLine, &parsedName, &parsedIsDirectory, &parsedSize),
              let parsedName else {
            return nil
        }

        name = parsedName as String
        isDirectory = parsedIsDirectory.boolValue
        size = parsedSize
    }
}
