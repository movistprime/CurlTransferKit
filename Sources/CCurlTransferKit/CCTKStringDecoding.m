#import "CCTKStringDecoding.h"

static NSStringEncoding const CCTKStringEncodings[] = {
    NSUTF8StringEncoding,
    NSISOLatin1StringEncoding,
    NSMacOSRomanStringEncoding,
};

NSString *CCTKStringFromData(NSData *data)
{
    if (!data.length) {
        return @"";
    }

    for (NSUInteger i = 0; i < sizeof(CCTKStringEncodings) / sizeof(CCTKStringEncodings[0]); i++) {
        NSString *string = [[NSString alloc] initWithData:data encoding:CCTKStringEncodings[i]];
        if (string) {
            return string;
        }
    }
    return @"";
}

NSString *CCTKStringFromBytes(const void *bytes, NSUInteger length)
{
    if (!bytes || !length) {
        return nil;
    }

    for (NSUInteger i = 0; i < sizeof(CCTKStringEncodings) / sizeof(CCTKStringEncodings[0]); i++) {
        NSString *string = [[NSString alloc] initWithBytes:bytes length:length encoding:CCTKStringEncodings[i]];
        if (string) {
            return string;
        }
    }
    return nil;
}
