import Foundation

public final class FTPFile {
    let transfer: CurlClient
    let size: Int64

    init(transfer: CurlClient, size: Int64) {
        self.transfer = transfer
        self.size = size
    }
}

public final class FTPClient {
    private let baseURL: URL
    private var listingClient: CurlClient?

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    deinit {
        listingClient?.reset()
    }

    public func listLines(at path: String) throws -> [String] {
        let url = baseURL.appendingPathComponent(path, isDirectory: true)
        let response = try transferForListing().fetch(urlString: url.absoluteString, range: nil)
        var lines: [String] = []
        response.bodyString.enumerateLines { line, _ in
            lines.append(line)
        }
        return lines
    }

    public func listEntries(at path: String) throws -> [FTPDirectoryEntry] {
        try listLines(at: path).compactMap { FTPDirectoryEntry(listingLine: $0) }
    }

    public func download(file path: String, to destinationURL: URL) throws {
        let url = baseURL.appendingPathComponent(path, isDirectory: false)
        let client = CurlClient(urlString: url.absoluteString)
        let response = try client.fetch(urlString: nil, range: nil)
        try response.bodyData.write(to: destinationURL, options: .atomic)
    }

    public func openFile(at path: String) throws -> FTPFile {
        let url = baseURL.appendingPathComponent(path, isDirectory: false)
        let client = CurlClient(urlString: url.absoluteString)
        let response = try client.probe(urlString: nil)
        guard let size = response.contentLength else {
            throw CocoaError(.fileReadUnknown)
        }
        return FTPFile(transfer: client, size: size)
    }

    public func read(_ file: FTPFile, offset: Int64, size: Int) throws -> Data {
        let end = offset + Int64(size) - 1
        let response = try file.transfer.fetch(urlString: nil, range: "\(offset)-\(end)")
        return response.bodyData
    }

    public func fileSize(_ file: FTPFile) -> Int64 {
        file.size
    }

    public func close(_ file: FTPFile) {
    }

    private func transferForListing() -> CurlClient {
        if let listingClient {
            return listingClient
        }
        let client = CurlClient(urlString: baseURL.absoluteString)
        listingClient = client
        return client
    }
}
