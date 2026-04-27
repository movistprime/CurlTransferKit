#import "CCurlTransferKit.h"
#import "CCTKStringDecoding.h"
#import <time.h>
#import "ftpparse.h"

BOOL CCTKParseFTPDirectoryEntry(NSString *listingLine,
                                NSString * _Nullable * _Nullable name,
                                BOOL * _Nullable isDirectory,
                                long long * _Nullable size)
{
    if (name) {
        *name = nil;
    }
    if (isDirectory) {
        *isDirectory = NO;
    }
    if (size) {
        *size = 0;
    }

    NSData *data = [listingLine dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return NO;
    }

    NSMutableData *buffer = [data mutableCopy];
    char terminator = 0;
    [buffer appendBytes:&terminator length:1];

    struct ftpparse parsed;
    if (!ftpparse(&parsed, buffer.mutableBytes, (int)data.length) || !parsed.name) {
        return NO;
    }

    NSString *entryName = CCTKStringFromBytes(parsed.name, (NSUInteger)parsed.namelen);
    if (!entryName.length) {
        return NO;
    }

    if (name) {
        *name = entryName;
    }
    if (isDirectory) {
        *isDirectory = parsed.flagtrycwd != 0;
    }
    if (size) {
        *size = parsed.size;
    }
    return YES;
}
