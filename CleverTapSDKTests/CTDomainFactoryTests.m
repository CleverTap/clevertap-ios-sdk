//
//  CTDomainFactoryTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 12/09/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
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

@end
