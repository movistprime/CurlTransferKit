#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct CCTKCurlClient CCTKCurlClient;

FOUNDATION_EXPORT CCTKCurlClient * _Nullable CCTKCurlClientCreate(NSString *urlString);
FOUNDATION_EXPORT void CCTKCurlClientDestroy(CCTKCurlClient * _Nullable client);
FOUNDATION_EXPORT void CCTKCurlClientReset(CCTKCurlClient * _Nullable client);

FOUNDATION_EXPORT BOOL CCTKCurlClientFetch(CCTKCurlClient *client,
                                           NSString * _Nullable urlString,
                                           NSString * _Nullable range,
                                           NSData * _Nullable * _Nullable bodyData,
                                           NSString * _Nullable * _Nullable bodyString,
                                           NSNumber * _Nullable * _Nullable contentLength,
                                           NSError * _Nullable * _Nullable error);

FOUNDATION_EXPORT BOOL CCTKCurlClientProbe(CCTKCurlClient *client,
                                           NSString * _Nullable urlString,
                                           NSData * _Nullable * _Nullable bodyData,
                                           NSString * _Nullable * _Nullable bodyString,
                                           NSNumber * _Nullable * _Nullable contentLength,
                                           NSError * _Nullable * _Nullable error);

FOUNDATION_EXPORT BOOL CCTKParseFTPDirectoryEntry(NSString *listingLine,
                                                  NSString * _Nullable * _Nullable name,
                                                  BOOL * _Nullable isDirectory,
                                                  long long * _Nullable size);

NS_ASSUME_NONNULL_END
