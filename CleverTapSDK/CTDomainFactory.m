//
//  CTDomainFactory.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 19/01/23.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import "CTDomainFactory.h"
#import "CTPreferences.h"
#import "CTConstants.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTRequestFactory.h"
#import "CleverTap+SCDomain.h"
#import "CTRequestSender.h"
#import "CTDispatchQueueManager.h"

NSString *const kREDIRECT_HEADER = @"X-WZRK-RD";
NSString *const kREDIRECT_NOTIF_VIEWED_HEADER = @"X-WZRK-SPIKY-RD";
NSString *const kMUTE_HEADER = @"X-WZRK-MUTE";

NSString *const kMUTED_TS_KEY = @"CLTAP_MUTED_TS_KEY";
NSTimeInterval const kMUTE_SECONDS = 24 * 60 * 60;

@interface CTDomainFactory ()
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTRequestSender *requestSender;

@property (nonatomic, assign) NSTimeInterval lastMutedTs;

#if CLEVERTAP_SSL_PINNING
@property(nonatomic, strong) CTPinnedNSURLSessionDelegate *urlSessionDelegate;
@property (nonatomic, strong) NSArray *sslCertNames;
#endif
@end

@implementation CTDomainFactory

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig* _Nonnull)config {
    self = [super init];
    if (self) {
        self.config = config;
        self.redirectDomain = [self loadRedirectDomain];
        self.redirectNotifViewedDomain = [self loadRedirectNotifViewedDomain];
        [self loadMutedTs];
    }
    return self;
}

#if CLEVERTAP_SSL_PINNING
- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig* _Nonnull)config pinnedNSURLSessionDelegate: (CTPinnedNSURLSessionDelegate* _Nonnull)pinnedNSURLSessionDelegate sslCertNames:(NSArray* _Nonnull)sslCertNames{
    self = [super init];
    if (self) {
        self.config = config;
        self.urlSessionDelegate = pinnedNSURLSessionDelegate;
        self.sslCertNames = sslCertNames;
        self.redirectDomain = [self loadRedirectDomain];
        self.redirectNotifViewedDomain = [self loadRedirectNotifViewedDomain];
        [self loadMutedTs];
    }
    return self;
}
#endif

- (void)setRequestSender:(CTRequestSender *)requestSender {
    _requestSender = requestSender;
    if (_requestSender && self.redirectDomain) {
        _requestSender.redirectDomain = self.redirectDomain;
    }
}

- (void)loadMutedTs {
    if (self.config.isDefaultInstance) {
        self.lastMutedTs = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kMUTED_TS_KEY config: self.config] withResetValue:[CTPreferences getIntForKey:kMUTED_TS_KEY withResetValue:0]];
    } else {
        self.lastMutedTs = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kMUTED_TS_KEY config: self.config] withResetValue:0];
    }
}

- (BOOL)isMuted {
    return [NSDate new].timeIntervalSince1970 - self.lastMutedTs < kMUTE_SECONDS;
}

- (void)clearRedirectDomain {
    self.redirectDomain = nil;
    self.redirectNotifViewedDomain = nil;
    [self persistRedirectDomain]; // if nil persist will remove
    self.redirectDomain = [self loadRedirectDomain]; // reload explicit domain if we have one else will be nil
    self.redirectNotifViewedDomain = [self loadRedirectNotifViewedDomain]; // reload explicit notification viewe domain if we have one else will be nil
}

- (NSString *)loadRedirectDomain {
    NSString *region = self.config.accountRegion;
    if (region) {
        region = [region stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
        if (region.length > 0) {
            self.explicitEndpointDomain = [NSString stringWithFormat:@"%@.%@", region, kCTApiDomain];
            return self.explicitEndpointDomain;
        }
    }
    NSString *proxyDomain = self.config.proxyDomain;
    if (proxyDomain) {
        proxyDomain = [proxyDomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
        if (proxyDomain.length > 0) {
            self.explicitEndpointDomain = proxyDomain;
            return self.explicitEndpointDomain;
        }
    }
    
    NSString *domain = nil;
    if (self.config.isDefaultInstance) {
        domain = [CTPreferences getStringForKey:[CTPreferences storageKeyWithSuffix:REDIRECT_DOMAIN_KEY config: self.config] withResetValue:[CTPreferences getStringForKey:REDIRECT_DOMAIN_KEY withResetValue:nil]];
    } else {
        domain = [CTPreferences getStringForKey:[CTPreferences storageKeyWithSuffix:REDIRECT_DOMAIN_KEY config: self.config] withResetValue:nil];
    }
    return domain;
}

- (NSString *)loadRedirectNotifViewedDomain {
    NSString *region = self.config.accountRegion;
    if (region) {
        region = [region stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
        if (region.length > 0) {
            self.explicitNotifViewedEndpointDomain = [NSString stringWithFormat:@"%@-%@", region, kCTNotifViewedApiDomain];
            return self.explicitNotifViewedEndpointDomain;
        }
    }
    NSString *spikyProxyDomain = self.config.spikyProxyDomain;
    if (spikyProxyDomain) {
        spikyProxyDomain = [spikyProxyDomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
        if (spikyProxyDomain.length > 0) {
            self.explicitNotifViewedEndpointDomain = spikyProxyDomain;
            return self.explicitNotifViewedEndpointDomain;
        }
    }
    NSString *domain = nil;
    if (self.config.isDefaultInstance) {
        domain = [CTPreferences getStringForKey:[CTPreferences storageKeyWithSuffix:REDIRECT_NOTIF_VIEWED_DOMAIN_KEY  config: self.config] withResetValue:[CTPreferences getStringForKey:REDIRECT_NOTIF_VIEWED_DOMAIN_KEY withResetValue:nil]];
    } else {
        domain = [CTPreferences getStringForKey:[CTPreferences storageKeyWithSuffix:REDIRECT_NOTIF_VIEWED_DOMAIN_KEY  config: self.config] withResetValue:nil];
    }
    return domain;
}

- (void)persistRedirectDomain {
    if (self.redirectDomain != nil) {
        [CTPreferences putString:self.redirectDomain forKey:[CTPreferences storageKeyWithSuffix:REDIRECT_DOMAIN_KEY config: self.config]];
#if CLEVERTAP_SSL_PINNING
        [self.urlSessionDelegate pinSSLCerts:self.sslCertNames forDomains:@[kCTApiDomain, self.redirectDomain]];
#endif
    } else {
        [CTPreferences removeObjectForKey:REDIRECT_DOMAIN_KEY];
        [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:REDIRECT_DOMAIN_KEY config: self.config]];
    }
}

- (void)persistRedirectNotifViewedDomain {
    if (self.redirectNotifViewedDomain != nil) {
        [CTPreferences putString:self.redirectNotifViewedDomain forKey:[CTPreferences storageKeyWithSuffix:REDIRECT_NOTIF_VIEWED_DOMAIN_KEY config: self.config]];
#if CLEVERTAP_SSL_PINNING
        [self.urlSessionDelegate pinSSLCerts:self.sslCertNames forDomains:@[kCTNotifViewedApiDomain, self.redirectNotifViewedDomain]];
#endif
    } else {
        [CTPreferences removeObjectForKey:REDIRECT_NOTIF_VIEWED_DOMAIN_KEY];
        [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:REDIRECT_NOTIF_VIEWED_DOMAIN_KEY config: self.config]];
    }
}

- (void)persistMutedTs {
    self.lastMutedTs = [NSDate new].timeIntervalSince1970;
    [CTPreferences putInt:self.lastMutedTs forKey:[CTPreferences storageKeyWithSuffix:kMUTED_TS_KEY config: self.config]];
}

#pragma mark - Handshake Handling

- (BOOL)needsHandshake {
    if ([self isMuted] || self.explicitEndpointDomain) {
        return NO;
    }
    return self.redirectDomain == nil;
}

- (void)performHandshakeWithCompletion:(void (^)(BOOL success))completion {
    if (!self.requestSender) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Cannot perform handshake: requestSender is nil", self);
        if (completion) {
            completion(NO);
        }
        return;
    }
    
    if (![self needsHandshake]) {
        [self onDomainAvailable];
        if (completion) {
            completion(YES);
        }
        return;
    }
    
    CleverTapLogInternal(self.config.logLevel, @"%@: Starting handshake with %@", self, kHANDSHAKE_URL);
    
    CTRequest *ctRequest = [CTRequestFactory helloRequestWithConfig:self.config];
    
    [ctRequest onResponse:^(NSData * _Nullable data, NSURLResponse * _Nullable response) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                NSDictionary *headers = httpResponse.allHeaderFields;
                [self updateDomainFromResponseHeaders:headers];
                [self updateNotificationViewedDomainFromResponseHeaders:headers];
                [self updateMutedFromResponseHeaders:headers];
                [self handleHandshakeSuccess];
                
                if (completion) {
                    completion(YES);
                }
            } else {
                [self onDomainUnavailable];
                CleverTapLogInternal(self.config.logLevel, @"%@: Handshake failed with status code %ld", self, (long)httpResponse.statusCode);
                if (completion) {
                    completion(NO);
                }
            }
        } else {
            [self onDomainUnavailable];
            CleverTapLogInternal(self.config.logLevel, @"%@: Handshake failed", self);
            if (completion) {
                completion(NO);
            }
        }
    }];
    
    [ctRequest onError:^(NSError * _Nullable error) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Handshake error: %@", self, error.localizedDescription);
        if (completion) {
            completion(NO);
        }
    }];
    
    [self.requestSender send:ctRequest];
}

- (void)updateMutedFromResponseHeaders:(NSDictionary *)headers {
    NSString *mutedString = headers[kMUTE_HEADER];
    BOOL muted = (mutedString == nil ? NO : [mutedString boolValue]);
    if (muted) {
        [self persistMutedTs];
        if (self.domainResolverDelegate && [self.domainResolverDelegate respondsToSelector:@selector(onMute)]) {
            [self.domainResolverDelegate onMute];
        }
    }
}

- (BOOL)updateDomainFromResponseHeaders:(NSDictionary *)headers {
    CleverTapLogInternal(self.config.logLevel, @"%@: Processing response with headers:%@", self, headers);
    BOOL shouldRedirect = NO;
    
    @try {
        NSString *redirectDomain = headers[kREDIRECT_HEADER];
        if (redirectDomain != nil && [redirectDomain isKindOfClass:[NSString class]] && redirectDomain.length > 0) {
            NSString *currentDomain = self.redirectDomain;
            self.redirectDomain = redirectDomain;
            if (![self.redirectDomain isEqualToString:currentDomain]) {
                shouldRedirect = YES;
                [self.requestSender setRedirectDomain:self.redirectDomain];
                [self persistRedirectDomain];
                CleverTapLogInternal(self.config.logLevel, @"%@: Redirect domain updated to: %@", self, redirectDomain);
                [self onDomainAvailable];
            }
        }
    } @catch(NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Error processing response headers: %@", self, e.debugDescription);
    }
    
    return shouldRedirect;
}

- (BOOL)updateNotificationViewedDomainFromResponseHeaders:(NSDictionary *)headers {
    CleverTapLogInternal(self.config.logLevel, @"%@: Processing response with headers:%@", self, headers);
    BOOL shouldRedirect = NO;
    
    @try {
        NSString *redirectNotifViewedDomain = headers[kREDIRECT_NOTIF_VIEWED_HEADER];
        if (redirectNotifViewedDomain != nil &&
            [redirectNotifViewedDomain isKindOfClass:[NSString class]] &&
            redirectNotifViewedDomain.length > 0) {
            NSString *currentDomain = self.redirectNotifViewedDomain;
            self.redirectNotifViewedDomain = redirectNotifViewedDomain;
            if (![self.redirectNotifViewedDomain isEqualToString:currentDomain]) {
                shouldRedirect = YES;
                [self persistRedirectNotifViewedDomain];
                CleverTapLogInternal(self.config.logLevel, @"%@: Notification viewed redirect domain updated to: %@", self, redirectNotifViewedDomain);
            }
        }
    } @catch(NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Error processing Notification Viewed response headers: %@", self, e.debugDescription);
    }
    
    return shouldRedirect;
}

- (void)handleHandshakeSuccess {
    CleverTapLogInternal(self.config.logLevel, @"%@: handshake success", self);
    
    if (self.domainResolverDelegate && [self.domainResolverDelegate respondsToSelector:@selector(onHandshakeSuccess)]) {
        [self.domainResolverDelegate onHandshakeSuccess];
    }
}

- (void)runSerialAsyncEnsureHandshake:(void(^ _Nullable)(BOOL success))block {
    [self.dispatchQueueManager runSerialAsync:^{
        if (![self needsHandshake]) {
            if (block) {
                block(YES);
            }
            return;
        }
        
        // Need to simulate a synchronous request
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self performHandshakeWithCompletion:^(BOOL success) {
            if (block) {
                [self.dispatchQueueManager runSerialAsync:^{
                    block(success);
                }];
            }
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }];
}

- (void)onDomainAvailable {
    NSString *dcDomain = [self domainString];
    if (self.domainDelegate && [self.domainDelegate respondsToSelector:@selector(onSCDomainAvailable:)]) {
        [self.domainDelegate onSCDomainAvailable: dcDomain];
    } else if (dcDomain == nil) {
        [self onDomainUnavailable];
    }
}

- (void)onDomainUnavailable {
    if (self.domainDelegate && [self.domainDelegate respondsToSelector:@selector(onSCDomainUnavailable)]) {
        [self.domainDelegate onSCDomainUnavailable];
    }
}

// Updates the format of the domain.
// From `in1.clevertap-prod.com` to region.auth.domain (i.e. in1.auth.clevertap-prod.com)
- (NSString *)domainString {
    if (self.redirectDomain == nil) {
        return nil;
    }
    
    NSArray *listItems = [self.redirectDomain componentsSeparatedByString:@"."];
    NSString *domainItem = [listItems[0] stringByAppendingString:@".auth"];
    for (int i = 1; i < listItems.count; i++ ) {
        NSString *dotString = [@"." stringByAppendingString: listItems[i]];
        domainItem = [domainItem stringByAppendingString: dotString];
    }
    self.signedCallDomain = domainItem;
    return domainItem;
}

@end
