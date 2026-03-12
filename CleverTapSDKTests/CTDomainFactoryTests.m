//
//  CTDomainFactoryTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 12/09/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CleverTapInstanceConfig.h"
#import "CTDomainFactory.h"
#import "CTDomainFactory+Tests.h"
#import "CTConstants.h"
#import "CTPreferences.h"

@interface CTDomainFactoryTests: XCTestCase
@property (nonatomic, strong) NSString *region;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDomainFactory *domainFactory;
@end

@implementation CTDomainFactoryTests

- (void)setUp {
    [super setUp];
    self.region = @"testRegion";
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken" accountRegion:self.region];
    self.domainFactory = [[CTDomainFactory alloc]initWithConfig:self.config];
}

- (void)tearDown {
    [self.domainFactory clearRedirectDomain];
    // Clean up persisted mute expiry to prevent state bleed between tests
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:@"CLTAP_MUTE_EXPIRY_TS_KEY" config:self.config]];
    self.domainFactory = nil;
    self.region = nil;
    [super tearDown];
}

- (void)testLoadRedirectDomainRegion {
    NSString *domain = [self.domainFactory loadRedirectDomain];
    NSString *result = [NSString stringWithFormat:@"%@.%@", self.region, kCTApiDomain].lowercaseString;
    XCTAssertEqualObjects(domain, result);
}

- (void)testLoadRedirectDomainCached {
    [self.domainFactory persistRedirectDomain];
    NSString *domain = [CTPreferences getStringForKey:[CTPreferences storageKeyWithSuffix:REDIRECT_DOMAIN_KEY config: self.config] withResetValue:nil];
    NSString *result = [self.domainFactory loadRedirectDomain];
    XCTAssertEqualObjects(domain, result);
}

- (void)testLoadRedirectDomainCustomHandShake {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken"];
    config.handshakeDomain = @"testCustomDomain";
    CTDomainFactory *domainFactory = [[CTDomainFactory alloc]initWithConfig:config];
    domainFactory.redirectDomain = config.handshakeDomain;
    [domainFactory persistRedirectDomain];
    
    NSString *domain = [domainFactory loadRedirectDomain];;
    XCTAssertEqualObjects(domain, config.handshakeDomain);
}

- (void)testLoadRedirectDomainProxy {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken" proxyDomain:@"testProxydomain"];
    CTDomainFactory *domainFactory = [[CTDomainFactory alloc]initWithConfig:config];

    NSString *domain = [domainFactory loadRedirectDomain];
    XCTAssertEqualObjects(domain, config.proxyDomain.lowercaseString);
}

#pragma mark - Mute Tests

- (void)testIsMuted_withNewDurationHeader_futureExpiry {
    NSTimeInterval twoDaysFromNow = [NSDate new].timeIntervalSince1970 + (2 * 24 * 60 * 60);
    long long muteExpiryMs = (long long)(twoDaysFromNow * 1000);
    NSDictionary *headers = @{
        @"X-WZRK-MUTE": @"true",
        @"X-WZRK-MUTE-DURATION": [NSString stringWithFormat:@"%lld", muteExpiryMs]
    };
    [self.domainFactory updateMutedFromResponseHeaders:headers];
    XCTAssertTrue([self.domainFactory isMuted], @"SDK should be muted when duration header has a future expiry");
    // Verify epoch ms → seconds conversion is correct
    NSTimeInterval diff = fabs(self.domainFactory.muteExpiryTs - twoDaysFromNow);
    XCTAssertLessThan(diff, 1.0, @"muteExpiryTs should be within 1 second of the value derived from the duration header");
}

- (void)testIsMuted_withNewDurationHeader_pastExpiry {
    NSTimeInterval oneDayAgo = [NSDate new].timeIntervalSince1970 - (24 * 60 * 60);
    long long muteExpiryMs = (long long)(oneDayAgo * 1000);
    NSDictionary *headers = @{
        @"X-WZRK-MUTE": @"true",
        @"X-WZRK-MUTE-DURATION": [NSString stringWithFormat:@"%lld", muteExpiryMs]
    };
    [self.domainFactory updateMutedFromResponseHeaders:headers];
    XCTAssertFalse([self.domainFactory isMuted], @"SDK should not be muted when duration header has a past expiry");
}

- (void)testIsMuted_withLegacyHeaderOnly {
    NSTimeInterval beforeCall = [NSDate new].timeIntervalSince1970;
    NSDictionary *headers = @{@"X-WZRK-MUTE": @"true"};
    [self.domainFactory updateMutedFromResponseHeaders:headers];
    XCTAssertTrue([self.domainFactory isMuted], @"SDK should be muted for 24h when only legacy header is received");
    // Verify expiry is set to ~now + 24h
    NSTimeInterval expectedExpiry = beforeCall + (24 * 60 * 60);
    NSTimeInterval diff = fabs(self.domainFactory.muteExpiryTs - expectedExpiry);
    XCTAssertLessThan(diff, 1.0, @"Legacy mute expiry should be within 1 second of now + 24h");
}

- (void)testIsMuted_withInfiniteExpiry {
    // 253402300799000 ms = 9999-12-31 23:59:59 UTC
    NSDictionary *headers = @{
        @"X-WZRK-MUTE": @"true",
        @"X-WZRK-MUTE-DURATION": @"253402300799000"
    };
    [self.domainFactory updateMutedFromResponseHeaders:headers];
    XCTAssertTrue([self.domainFactory isMuted], @"SDK should be muted indefinitely when INFINITE_MUTE_EXPIRY is received");
}

- (void)testIsMuted_noMuteHeaders {
    [self.domainFactory updateMutedFromResponseHeaders:@{}];
    XCTAssertFalse([self.domainFactory isMuted], @"SDK should not be muted when no mute headers are present");
}

- (void)testMuteExpiry_persistedAndLoaded {
    NSTimeInterval futureExpiry = [NSDate new].timeIntervalSince1970 + (4 * 24 * 60 * 60);
    [self.domainFactory persistMutedExpiry:futureExpiry];

    CTDomainFactory *newInstance = [[CTDomainFactory alloc] initWithConfig:self.config];
    XCTAssertTrue([newInstance isMuted], @"Mute state should survive re-initialization from persisted storage");
}

- (void)testIsMuted_expiredAfterUpgrade {
    // Simulate SDK upgrade where new key is absent (muteExpiryTs defaults to 0)
    self.domainFactory.muteExpiryTs = 0;
    XCTAssertFalse([self.domainFactory isMuted], @"SDK should not be muted when muteExpiryTs is 0 (fresh install or upgrade)");
}

- (void)testNeedsHandshake_returnsFalseWhenMuted {
    // Use a config without a region so needsHandshake can actually return YES
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"muteHandshakeTest" accountToken:@"testToken"];
    CTDomainFactory *factory = [[CTDomainFactory alloc] initWithConfig:config];
    XCTAssertTrue([factory needsHandshake], @"Should need handshake when not muted and no domain set");

    NSTimeInterval futureExpiry = [NSDate new].timeIntervalSince1970 + 3600;
    [factory persistMutedExpiry:futureExpiry];
    XCTAssertFalse([factory needsHandshake], @"Should NOT need handshake when muted");

    // Clean up
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:@"CLTAP_MUTE_EXPIRY_TS_KEY" config:config]];
}

- (void)testOnMuteDelegateCalledWhenMuted {
    id mockDelegate = OCMProtocolMock(@protocol(CTDomainResolverDelegate));
    self.domainFactory.domainResolverDelegate = mockDelegate;

    NSTimeInterval futureExpiry = [NSDate new].timeIntervalSince1970 + 3600;
    long long muteExpiryMs = (long long)(futureExpiry * 1000);
    NSDictionary *headers = @{
        @"X-WZRK-MUTE": @"true",
        @"X-WZRK-MUTE-DURATION": [NSString stringWithFormat:@"%lld", muteExpiryMs]
    };
    [self.domainFactory updateMutedFromResponseHeaders:headers];

    OCMVerify([mockDelegate onMute]);
}

- (void)testOnMuteDelegateNotCalledWhenNotMuted {
    id mockDelegate = OCMStrictProtocolMock(@protocol(CTDomainResolverDelegate));
    self.domainFactory.domainResolverDelegate = mockDelegate;

    [self.domainFactory updateMutedFromResponseHeaders:@{}];
    // OCMStrictProtocolMock will fail the test if any unexpected method is called
    OCMVerifyAll(mockDelegate);
}

- (void)testIsMuted_withExplicitFalseHeader_doesNotMute {
    NSDictionary *headers = @{@"X-WZRK-MUTE": @"false"};
    [self.domainFactory updateMutedFromResponseHeaders:headers];
    XCTAssertFalse([self.domainFactory isMuted], @"Explicit X-WZRK-MUTE:false should not mute the SDK");
}

- (void)testIsMuted_durationHeaderAloneWithoutMuteHeader_doesNotMute {
    NSTimeInterval futureExpiry = [NSDate new].timeIntervalSince1970 + 3600;
    NSDictionary *headers = @{
        @"X-WZRK-MUTE-DURATION": [NSString stringWithFormat:@"%lld", (long long)(futureExpiry * 1000)]
    };
    [self.domainFactory updateMutedFromResponseHeaders:headers];
    XCTAssertFalse([self.domainFactory isMuted], @"X-WZRK-MUTE-DURATION alone without X-WZRK-MUTE:true should not mute");
}

- (void)testRemute_newDurationOverwritesOld {
    // First mute: 8 days
    NSTimeInterval eightDays = [NSDate new].timeIntervalSince1970 + (8 * 86400);
    [self.domainFactory persistMutedExpiry:eightDays];
    XCTAssertEqualWithAccuracy(self.domainFactory.muteExpiryTs, eightDays, 1.0);

    // Re-mute: 1 day (new response from backend)
    NSTimeInterval oneDay = [NSDate new].timeIntervalSince1970 + 86400;
    NSDictionary *headers = @{
        @"X-WZRK-MUTE": @"true",
        @"X-WZRK-MUTE-DURATION": [NSString stringWithFormat:@"%lld", (long long)(oneDay * 1000)]
    };
    [self.domainFactory updateMutedFromResponseHeaders:headers];

    XCTAssertTrue([self.domainFactory isMuted], @"Should still be muted after re-mute");
    NSTimeInterval diff = fabs(self.domainFactory.muteExpiryTs - oneDay);
    XCTAssertLessThan(diff, 1.0, @"Re-mute should overwrite muteExpiryTs with the new duration");
}

- (void)testIsMuted_atExactExpiry_isNotMuted {
    // Set expiry to 1 second in the past
    NSTimeInterval justExpired = [NSDate new].timeIntervalSince1970 - 1;
    self.domainFactory.muteExpiryTs = justExpired;
    XCTAssertFalse([self.domainFactory isMuted], @"Should not be muted 1 second after expiry");
}

#pragma mark - needsHandshake Tests

- (void)testNeedsHandshake_returnsTrueWhenNoDomainAndNotMuted {
    // Config without region or proxy so no explicit domain is set
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testNoRegion" accountToken:@"testToken"];
    CTDomainFactory *factory = [[CTDomainFactory alloc] initWithConfig:config];
    XCTAssertTrue([factory needsHandshake], @"needsHandshake should be YES when no domain is set and not muted");
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:@"CLTAP_MUTE_EXPIRY_TS_KEY" config:config]];
}

- (void)testNeedsHandshake_returnsFalseWhenRedirectDomainAlreadySet {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testRedirectDomain" accountToken:@"testToken"];
    CTDomainFactory *factory = [[CTDomainFactory alloc] initWithConfig:config];
    factory.redirectDomain = @"eu1.clevertap-prod.com";
    XCTAssertFalse([factory needsHandshake], @"needsHandshake should be NO when redirectDomain is already set");
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:@"CLTAP_MUTE_EXPIRY_TS_KEY" config:config]];
}

- (void)testNeedsHandshake_returnsFalseWhenExplicitEndpointDomain {
    // Region config sets explicitEndpointDomain
    XCTAssertFalse([self.domainFactory needsHandshake], @"needsHandshake should be NO when an explicit endpoint domain is configured via region");
}

#pragma mark - updateDomainFromResponseHeaders Tests

- (void)testUpdateDomainFromResponseHeaders_setsRedirectDomain {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testUpdateDomain" accountToken:@"testToken"];
    CTDomainFactory *factory = [[CTDomainFactory alloc] initWithConfig:config];

    NSDictionary *headers = @{@"X-WZRK-RD": @"in1.clevertap-prod.com"};
    BOOL shouldRedirect = [factory updateDomainFromResponseHeaders:headers];

    XCTAssertTrue(shouldRedirect, @"Should indicate a redirect when a new domain is received");
    XCTAssertEqualObjects(factory.redirectDomain, @"in1.clevertap-prod.com");

    [factory clearRedirectDomain];
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:@"CLTAP_MUTE_EXPIRY_TS_KEY" config:config]];
}

- (void)testUpdateDomainFromResponseHeaders_returnsFalseWhenSameDomain {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testSameDomain" accountToken:@"testToken"];
    CTDomainFactory *factory = [[CTDomainFactory alloc] initWithConfig:config];
    factory.redirectDomain = @"eu1.clevertap-prod.com";

    NSDictionary *headers = @{@"X-WZRK-RD": @"eu1.clevertap-prod.com"};
    BOOL shouldRedirect = [factory updateDomainFromResponseHeaders:headers];

    XCTAssertFalse(shouldRedirect, @"shouldRedirect should be NO when the domain header matches the current domain");

    [factory clearRedirectDomain];
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:@"CLTAP_MUTE_EXPIRY_TS_KEY" config:config]];
}

- (void)testUpdateDomainFromResponseHeaders_noHeaderDoesNotChangeRedirectDomain {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testNoRedirectHeader" accountToken:@"testToken"];
    CTDomainFactory *factory = [[CTDomainFactory alloc] initWithConfig:config];

    BOOL shouldRedirect = [factory updateDomainFromResponseHeaders:@{}];

    XCTAssertFalse(shouldRedirect, @"No redirect header should not trigger a redirect");
    XCTAssertNil(factory.redirectDomain, @"redirectDomain should remain nil when no redirect header is present");
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:@"CLTAP_MUTE_EXPIRY_TS_KEY" config:config]];
}

- (void)testUpdateNotificationViewedDomainFromResponseHeaders_setsDomain {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testNotifViewedDomain" accountToken:@"testToken"];
    CTDomainFactory *factory = [[CTDomainFactory alloc] initWithConfig:config];

    NSDictionary *headers = @{@"X-WZRK-SPIKY-RD": @"spiky.clevertap-prod.com"};
    BOOL shouldRedirect = [factory updateNotificationViewedDomainFromResponseHeaders:headers];

    XCTAssertTrue(shouldRedirect);
    XCTAssertEqualObjects(factory.redirectNotifViewedDomain, @"spiky.clevertap-prod.com");

    // Clean up both persisted redirect domains so state does not bleed into subsequent runs
    [factory clearRedirectDomain];
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:@"CLTAP_MUTE_EXPIRY_TS_KEY" config:config]];
}

@end
