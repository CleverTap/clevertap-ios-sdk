//
//  CTPlistInfoTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTPlistInfo.h"
#import "CleverTap.h"

// Expose private method for testing
@interface CTPlistInfo (Test)
- (void)setEncryption:(NSString *)encryptionLevel;
@end

@interface CTPlistInfoTest : XCTestCase
@property (nonatomic, strong) CTPlistInfo *plist;
@end

@implementation CTPlistInfoTest

- (void)setUp {
    self.plist = [[CTPlistInfo alloc] init];
}

#pragma mark - setEncryption:

- (void)test_setEncryption_zeroString_setsNone {
    [self.plist setEncryption:@"0"];
    XCTAssertEqual(self.plist.encryptionLevel, CleverTapEncryptionNone);
}

- (void)test_setEncryption_oneString_setsMedium {
    [self.plist setEncryption:@"1"];
    XCTAssertEqual(self.plist.encryptionLevel, CleverTapEncryptionMedium);
}

- (void)test_setEncryption_twoString_setsHigh {
    [self.plist setEncryption:@"2"];
    XCTAssertEqual(self.plist.encryptionLevel, CleverTapEncryptionHigh);
}

- (void)test_setEncryption_invalidString_setsNone {
    [self.plist setEncryption:@"invalid"];
    XCTAssertEqual(self.plist.encryptionLevel, CleverTapEncryptionNone);
}

- (void)test_setEncryption_nil_setsNone {
    [self.plist setEncryption:nil];
    XCTAssertEqual(self.plist.encryptionLevel, CleverTapEncryptionNone);
}

#pragma mark - setCredentialsWithAccountID:token:region:

- (void)test_setCredentials_withRegion_setsProperties {
    [self.plist setCredentialsWithAccountID:@"acc1" token:@"tok1" region:@"eu1"];
    XCTAssertEqualObjects(self.plist.accountId, @"acc1");
    XCTAssertEqualObjects(self.plist.accountToken, @"tok1");
    XCTAssertEqualObjects(self.plist.accountRegion, @"eu1");
}

#pragma mark - setCredentialsWithAccountID:token:proxyDomain:

- (void)test_setCredentials_withProxyDomain_setsProperties {
    [self.plist setCredentialsWithAccountID:@"acc2" token:@"tok2" proxyDomain:@"proxy.example.com"];
    XCTAssertEqualObjects(self.plist.accountId, @"acc2");
    XCTAssertEqualObjects(self.plist.accountToken, @"tok2");
    XCTAssertEqualObjects(self.plist.proxyDomain, @"proxy.example.com");
}

#pragma mark - setCredentialsWithAccountID:token:proxyDomain:spikyProxyDomain:

- (void)test_setCredentials_withSpikyProxyDomain_setsProperties {
    [self.plist setCredentialsWithAccountID:@"acc3" token:@"tok3" proxyDomain:@"proxy.example.com" spikyProxyDomain:@"spiky.example.com"];
    XCTAssertEqualObjects(self.plist.accountId, @"acc3");
    XCTAssertEqualObjects(self.plist.accountToken, @"tok3");
    XCTAssertEqualObjects(self.plist.proxyDomain, @"proxy.example.com");
    XCTAssertEqualObjects(self.plist.spikyProxyDomain, @"spiky.example.com");
}

- (void)test_setCredentials_withNilSpikyProxyDomain_setsNil {
    [self.plist setCredentialsWithAccountID:@"acc4" token:@"tok4" proxyDomain:@"proxy.example.com" spikyProxyDomain:nil];
    XCTAssertNil(self.plist.spikyProxyDomain);
}

#pragma mark - setCredentialsWithAccountID:token:proxyDomain:spikyProxyDomain:handshakeDomain:

- (void)test_setCredentials_withHandshakeDomain_setsProperties {
    [self.plist setCredentialsWithAccountID:@"acc5" token:@"tok5" proxyDomain:@"proxy.example.com" spikyProxyDomain:@"spiky.example.com" handshakeDomain:@"handshake.example.com"];
    XCTAssertEqualObjects(self.plist.accountId, @"acc5");
    XCTAssertEqualObjects(self.plist.accountToken, @"tok5");
    XCTAssertEqualObjects(self.plist.proxyDomain, @"proxy.example.com");
    XCTAssertEqualObjects(self.plist.spikyProxyDomain, @"spiky.example.com");
    XCTAssertEqualObjects(self.plist.handshakeDomain, @"handshake.example.com");
}

@end
