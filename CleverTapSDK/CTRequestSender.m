//
//  CTRequestSender.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 11/01/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTRequestSender.h"
#import "CTConstants.h"

#if CLEVERTAP_SSL_PINNING
#import "CTPinnedNSURLSessionDelegate.h"
#endif

@interface CTRequestSender ()
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSString *redirectDomain;
@property (nonatomic, assign, readonly) BOOL sslPinningEnabled;

#if CLEVERTAP_SSL_PINNING
@property(nonatomic, strong) CTPinnedNSURLSessionDelegate *urlSessionDelegate;
@property (nonatomic, strong) NSArray *sslCertNames;
#endif
@end

@implementation CTRequestSender

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig *_Nonnull)config redirectDomain:(NSString* _Nonnull)redirectDomain {
    
    if ((self = [super init])) {
        self.config = config;
        self.redirectDomain = redirectDomain;
        [self setUpUrlSession];

    }
    return self;
}

#if CLEVERTAP_SSL_PINNING
- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig *_Nonnull)config redirectDomain:(NSString* _Nonnull)redirectDomain pinnedNSURLSessionDelegate: (CTPinnedNSURLSessionDelegate* _Nonnull)pinnedNSURLSessionDelegate sslCertNames:(NSArray* _Nonnull)sslCertNames {
    if ((self = [super init])) {
        self.config = config;
        self.urlSessionDelegate = pinnedNSURLSessionDelegate;
        self.sslCertNames = sslCertNames;
        self.redirectDomain = redirectDomain;
        [self setUpUrlSession];

    }
    return self;
}
#endif

- (void)setUpUrlSession {
    if (!_urlSession) {
        NSURLSessionConfiguration *sc = [NSURLSessionConfiguration defaultSessionConfiguration];
        [sc setHTTPAdditionalHeaders:@{
            @"Content-Type" : @"application/json; charset=utf-8"
        }];
        
        sc.timeoutIntervalForRequest = CLTAP_REQUEST_TIME_OUT_INTERVAL;
        sc.timeoutIntervalForResource = CLTAP_REQUEST_TIME_OUT_INTERVAL;
        [sc setHTTPShouldSetCookies:NO];
        [sc setRequestCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        
#if CLEVERTAP_SSL_PINNING
        _sslPinningEnabled = YES;
        self.urlSessionDelegate = [[CTPinnedNSURLSessionDelegate alloc] initWithConfig:self.config];
        NSMutableArray *domains = [NSMutableArray arrayWithObjects:kCTApiDomain, nil];
        if (self.redirectDomain && ![self.redirectDomain isEqualToString:kCTApiDomain]) {
            [domains addObject:self.redirectDomain];
        }
        // WITH SSL PINNING ENABLED AND REGION NOT SPECIFIED BY THE USER, WE WILL DEFAULT TO EU1 AND PIN THE CERT TO EU1
        else if (!self.redirectDomain) {
            [domains addObject:[NSString stringWithFormat:@"eu1.%@", kCTApiDomain]];
        }
        [self.urlSessionDelegate pinSSLCerts:_sslCertNames forDomains:domains];
        self.urlSession = [NSURLSession sessionWithConfiguration:sc delegate:self.urlSessionDelegate delegateQueue:nil];
#else
        _sslPinningEnabled = NO;
        _urlSession = [NSURLSession sessionWithConfiguration:sc];
#endif
    }
}

- (void)send:(CTRequest *_Nonnull)ctRequest {
    NSURLSessionDataTask *task = [_urlSession
                                  dataTaskWithRequest:ctRequest.urlRequest
                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            ctRequest.errorBlock(error);
        }
        ctRequest.responseBlock(data, response);
    }];
    [task resume];
}

@end
