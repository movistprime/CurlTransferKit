#import "CCurlTransferKit.h"
#import "CCTKStringDecoding.h"
#import <curl/curl.h>
#import <stdlib.h>
#import <string.h>
#import <strings.h>

static NSString * const CCTKCurlClientErrorDomain = @"CurlTransferKit.CurlClientError";

struct CCTKCurlClient {
    CURL *curl;
    char *urlString;
    BOOL usesEPSV;
};

static void CCTKInitializeCurl(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        curl_global_init(CURL_GLOBAL_DEFAULT);
    });
}

static void CCTKAssignError(NSError * _Nullable * _Nullable error, NSInteger code, NSString *message)
{
    if (error) {
        *error = [NSError errorWithDomain:CCTKCurlClientErrorDomain
                                     code:code
                                 userInfo:@{NSLocalizedDescriptionKey: message}];
    }
}

static size_t CCTKWrite(void *ptr, size_t size, size_t nmemb, void *userdata)
{
    NSMutableData *data = (__bridge NSMutableData *)userdata;
    const size_t count = size * nmemb;
    [data appendBytes:ptr length:count];
    return count;
}

static BOOL CCTKURLStringIsFTP(const char *urlString)
{
    if (!urlString) {
        return NO;
    }
    return strncasecmp(urlString, "ftp://", 6) == 0 || strncasecmp(urlString, "ftps://", 7) == 0;
}

static BOOL CCTKShouldRetryWithoutEPSV(CURLcode code)
{
    switch (code) {
        case CURLE_FTP_WEIRD_PASV_REPLY:
        case CURLE_FTP_CANT_GET_HOST:
        case CURLE_COULDNT_CONNECT:
        case CURLE_OPERATION_TIMEDOUT:
            return YES;
        default:
            return NO;
    }
}

static BOOL CCTKCurlClientSetURLString(CCTKCurlClient *client, NSString *urlString)
{
    const char *utf8 = urlString.UTF8String;
    if (!utf8 || !utf8[0]) {
        return NO;
    }

    char *copy = strdup(utf8);
    if (!copy) {
        return NO;
    }

    free(client->urlString);
    client->urlString = copy;
    return YES;
}

CCTKCurlClient *CCTKCurlClientCreate(NSString *urlString)
{
    CCTKInitializeCurl();

    CCTKCurlClient *client = calloc(1, sizeof(CCTKCurlClient));
    if (!client) {
        return NULL;
    }

    client->curl = curl_easy_init();
    client->usesEPSV = YES;
    if (urlString.length && !CCTKCurlClientSetURLString(client, urlString)) {
        CCTKCurlClientDestroy(client);
        return NULL;
    }
    return client;
}

void CCTKCurlClientDestroy(CCTKCurlClient *client)
{
    if (!client) {
        return;
    }
    if (client->curl) {
        curl_easy_cleanup(client->curl);
    }
    free(client->urlString);
    free(client);
}

void CCTKCurlClientReset(CCTKCurlClient *client)
{
    if (!client) {
        return;
    }
    if (client->curl) {
        curl_easy_cleanup(client->curl);
    }
    client->curl = curl_easy_init();
    client->usesEPSV = YES;
}

static BOOL CCTKCurlClientPerform(CCTKCurlClient *client,
                                  NSString *urlString,
                                  NSString *range,
                                  BOOL isHead,
                                  NSData * _Nullable * _Nullable bodyData,
                                  NSString * _Nullable * _Nullable bodyString,
                                  NSNumber * _Nullable * _Nullable contentLength,
                                  NSError * _Nullable * _Nullable error)
{
    if (bodyData) {
        *bodyData = nil;
    }
    if (bodyString) {
        *bodyString = nil;
    }
    if (contentLength) {
        *contentLength = nil;
    }

    if (!client) {
        CCTKAssignError(error, -1, @"invalid client");
        return NO;
    }
    if (urlString && !CCTKCurlClientSetURLString(client, urlString)) {
        CCTKAssignError(error, -2, @"invalid address");
        return NO;
    }
    if (!client->urlString) {
        CCTKAssignError(error, -2, @"invalid address");
        return NO;
    }
    if (!client->curl) {
        client->curl = curl_easy_init();
    }
    if (!client->curl) {
        CCTKAssignError(error, -3, @"failed to initialize curl");
        return NO;
    }

    NSMutableData *data = [NSMutableData data];
    char errorBuffer[CURL_ERROR_SIZE] = {0};

    curl_easy_setopt(client->curl, CURLOPT_URL, client->urlString);
    curl_easy_setopt(client->curl, CURLOPT_ERRORBUFFER, errorBuffer);
    curl_easy_setopt(client->curl, CURLOPT_WRITEFUNCTION, CCTKWrite);
    curl_easy_setopt(client->curl, CURLOPT_WRITEDATA, (__bridge void *)data);
    curl_easy_setopt(client->curl, CURLOPT_NOSIGNAL, 1L);
    curl_easy_setopt(client->curl, CURLOPT_NOBODY, isHead ? 1L : 0L);
    curl_easy_setopt(client->curl, CURLOPT_CUSTOMREQUEST, NULL);
    if (!isHead) {
        curl_easy_setopt(client->curl, CURLOPT_HTTPGET, 1L);
    }
    curl_easy_setopt(client->curl, CURLOPT_RANGE, range.length ? range.UTF8String : NULL);
    if (CCTKURLStringIsFTP(client->urlString)) {
        curl_easy_setopt(client->curl, CURLOPT_FTP_USE_EPSV, client->usesEPSV ? 1L : 0L);
#ifdef CURLOPT_FTP_SKIP_PASV_IP
        curl_easy_setopt(client->curl, CURLOPT_FTP_SKIP_PASV_IP, 1L);
#endif
    }

    CURLcode code = curl_easy_perform(client->curl);
    if (code != CURLE_OK && client->usesEPSV && CCTKURLStringIsFTP(client->urlString) && CCTKShouldRetryWithoutEPSV(code)) {
        client->usesEPSV = NO;
        [data setLength:0];
        memset(errorBuffer, 0, sizeof(errorBuffer));
        curl_easy_setopt(client->curl, CURLOPT_FTP_USE_EPSV, 0L);
        code = curl_easy_perform(client->curl);
    }
    if (code != CURLE_OK) {
        NSString *message = errorBuffer[0] ? [NSString stringWithUTF8String:errorBuffer] : @(curl_easy_strerror(code));
        CCTKAssignError(error, code, message ?: @"curl error");
        return NO;
    }

    NSNumber *lengthNumber = nil;
#ifdef CURLINFO_CONTENT_LENGTH_DOWNLOAD_T
    curl_off_t length = -1;
    if (curl_easy_getinfo(client->curl, CURLINFO_CONTENT_LENGTH_DOWNLOAD_T, &length) == CURLE_OK && 0 <= length) {
        lengthNumber = @(length);
    }
#else
    double length = -1;
    if (curl_easy_getinfo(client->curl, CURLINFO_CONTENT_LENGTH_DOWNLOAD, &length) == CURLE_OK && 0 <= length) {
        lengthNumber = @((long long)length);
    }
#endif

    NSData *responseData = [data copy];
    if (bodyData) {
        *bodyData = responseData;
    }
    if (bodyString) {
        *bodyString = CCTKStringFromData(responseData);
    }
    if (contentLength) {
        *contentLength = lengthNumber;
    }
    return YES;
}

BOOL CCTKCurlClientFetch(CCTKCurlClient *client,
                         NSString *urlString,
                         NSString *range,
                         NSData * _Nullable * _Nullable bodyData,
                         NSString * _Nullable * _Nullable bodyString,
                         NSNumber * _Nullable * _Nullable contentLength,
                         NSError * _Nullable * _Nullable error)
{
    return CCTKCurlClientPerform(client, urlString, range, NO, bodyData, bodyString, contentLength, error);
}

BOOL CCTKCurlClientProbe(CCTKCurlClient *client,
                         NSString *urlString,
                         NSData * _Nullable * _Nullable bodyData,
                         NSString * _Nullable * _Nullable bodyString,
                         NSNumber * _Nullable * _Nullable contentLength,
                         NSError * _Nullable * _Nullable error)
{
    return CCTKCurlClientPerform(client, urlString, nil, YES, bodyData, bodyString, contentLength, error);
}
