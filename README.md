# CurlTransferKit

Small Swift package for curl-backed transfers and FTP directory access on macOS.

## Features

- Fetch URL contents with libcurl.
- Probe remote file metadata, including content length when available.
- Read byte ranges from FTP files.
- List FTP directories and parse common FTP `LIST` entry formats.

## Requirements

- macOS 11 or later
- Swift Package Manager
- libcurl

## Usage

### CurlClient

```swift
import CurlTransferKit

let client = CurlClient(urlString: "https://example.com/file.txt")
let response = try client.fetch()

print(response.bodyData)
print(response.bodyString)
print(response.contentLength as Any)
```

Range requests can be made with curl range syntax:

```swift
let response = try client.fetch(range: "0-1023")
```

### FTPClient

```swift
import CurlTransferKit
import Foundation

let client = FTPClient(baseURL: URL(string: "ftp://user:password@example.com/")!)

let lines = try client.listLines(at: "/")
let entries = try client.listEntries(at: "/")

for entry in entries {
    print(entry.name, entry.isDirectory, entry.size)
}
```

### Reading FTP Files

```swift
let file = try client.openFile(at: "/movie.mp4")
let chunk = try client.read(file, offset: 0, size: 64 * 1024)
let size = client.fileSize(file)
client.close(file)
```

## Public Types

- `CurlClient`: low-level curl transfer client.
- `CurlResponse`: transfer result containing `bodyData`, `bodyString`, and optional `contentLength`.
- `FTPClient`: FTP convenience client for listing, downloading, opening, and range-reading files.
- `FTPDirectoryEntry`: parsed FTP directory entry.
- `FTPFile`: open FTP file handle used by `FTPClient`.

## Testing

```sh
swift test
```

In a restricted sandbox, SwiftPM may need writable cache paths:

```sh
mkdir -p /tmp/ctk-swiftpm /tmp/ctk-clang-module-cache
CLANG_MODULE_CACHE_PATH=/tmp/ctk-clang-module-cache \
swift test --disable-sandbox --scratch-path /tmp/ctk-swiftpm
```

## Third-Party Code

FTP `LIST` parsing uses D. J. Bernstein's `ftpparse` 20001223 source in `Sources/CCurlTransferKit/ftpparse.c` and `Sources/CCurlTransferKit/ftpparse.h`.

DJB's distributor FAQ states that `ftpparse` is public domain as of 2023-09-29 and may be distributed using `LicenseRef-PD-hp OR CC0-1.0 OR 0BSD OR MIT-0 OR MIT`.
