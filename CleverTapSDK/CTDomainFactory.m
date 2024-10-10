//
//  CTDomainFactory.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 19/01/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTDomainFactory.h"
#import "CTPreferences.h"
#import "CTConstants.h"
#import "CleverTapInstanceConfigPrivate.h"

@interface CTDomainFactory ()
@property (nonatomic, strong) CleverTapInstanceConfig *config;

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
    }
    return self;
}
#endif

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
            self.explictEndpointDomain = [NSString stringWithFormat:@"%@.%@", region, kCTApiDomain];
            return self.explictEndpointDomain;
        }
    }
    NSString *proxyDomain = self.config.proxyDomain;
    if (proxyDomain) {
        proxyDomain = [proxyDomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
        if (proxyDomain.length > 0) {
            self.explictEndpointDomain = proxyDomain;
            return self.explictEndpointDomain;
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
            self.explictNotifViewedEndpointDomain = [NSString stringWithFormat:@"%@-%@", region, kCTNotifViewedApiDomain];
            return self.explictNotifViewedEndpointDomain;
        }
    }
    NSString *spikyProxyDomain = self.config.spikyProxyDomain;
    if (spikyProxyDomain) {
        spikyProxyDomain = [spikyProxyDomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
        if (spikyProxyDomain.length > 0) {
            self.explictNotifViewedEndpointDomain = spikyProxyDomain;
            return self.explictNotifViewedEndpointDomain;
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

@end
