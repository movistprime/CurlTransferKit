import CCurlTransferKit
import Foundation

public struct CurlResponse {
    public let bodyData: Data
    public let bodyString: String
    public let contentLength: Int64?
}

public final class CurlClient {
    private let handle: OpaquePointer

    public init(urlString: String) {
        guard let handle = CCTKCurlClientCreate(urlString) else {
            preconditionFailure("failed to create curl client")
        }
        self.handle = handle
    }

    deinit {
        CCTKCurlClientDestroy(handle)
    }

    public func fetch(urlString: String? = nil, range: String? = nil) throws -> CurlResponse {
        var bodyData: NSData?
        var bodyString: NSString?
        var contentLength: NSNumber?
        var error: NSError?

        guard CCTKCurlClientFetch(handle, urlString, range, &bodyData, &bodyString, &contentLength, &error) else {
            throw error ?? CocoaError(.fileReadUnknown)
        }
        return CurlResponse(bodyData: bodyData as Data? ?? Data(),
                            bodyString: bodyString as String? ?? "",
                            contentLength: contentLength?.int64Value)
    }

    public func probe(urlString: String? = nil) throws -> CurlResponse {
        var bodyData: NSData?
        var bodyString: NSString?
        var contentLength: NSNumber?
        var error: NSError?

        guard CCTKCurlClientProbe(handle, urlString, &bodyData, &bodyString, &contentLength, &error) else {
            throw error ?? CocoaError(.fileReadUnknown)
        }
        return CurlResponse(bodyData: bodyData as Data? ?? Data(),
                            bodyString: bodyString as String? ?? "",
                            contentLength: contentLength?.int64Value)
    }

    public func reset() {
        CCTKCurlClientReset(handle)
    }
}
