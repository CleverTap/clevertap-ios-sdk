//
//  CleverTapInstanceConfigTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"

@interface CleverTapInstanceConfigTest : XCTestCase
@end

@implementation CleverTapInstanceConfigTest

#pragma mark - initWithAccountId:accountToken:

- (void)test_initWithAccountId_token_setsAccountIdAndToken {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1"];
    XCTAssertEqualObjects(config.accountId, @"acc1");
    XCTAssertEqualObjects(config.accountToken, @"tok1");
}

- (void)test_initWithAccountId_token_regionIsNil {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1"];
    XCTAssertNil(config.accountRegion);
}

- (void)test_initWithAccountId_token_enablePersonalizationIsYes {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1"];
    XCTAssertTrue(config.enablePersonalization);
}

- (void)test_initWithAccountId_token_queueLabelContainsAccountId {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1"];
    XCTAssertTrue([config.queueLabel containsString:@"acc1"]);
}

#pragma mark - initWithAccountId:accountToken:accountRegion:

- (void)test_initWithAccountId_token_region_setsRegion {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1" accountRegion:@"eu1"];
    XCTAssertEqualObjects(config.accountRegion, @"eu1");
}

#pragma mark - initWithAccountId:accountToken:proxyDomain:

- (void)test_initWithAccountId_token_proxyDomain_setsProxyDomain {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1" proxyDomain:@"proxy.example.com"];
    XCTAssertEqualObjects(config.proxyDomain, @"proxy.example.com");
}

#pragma mark - initWithAccountId:accountToken:proxyDomain:spikyProxyDomain:

- (void)test_initWithAccountId_token_proxyDomain_spikyProxy_setsBoth {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1" proxyDomain:@"proxy.example.com" spikyProxyDomain:@"spiky.example.com"];
    XCTAssertEqualObjects(config.proxyDomain, @"proxy.example.com");
    XCTAssertEqualObjects(config.spikyProxyDomain, @"spiky.example.com");
}

#pragma mark - dataArchiveFileNameWithAccountId:

- (void)test_dataArchiveFileName_containsAccountId {
    NSString *filename = [CleverTapInstanceConfig dataArchiveFileNameWithAccountId:@"myAccount"];
    XCTAssertTrue([filename containsString:@"myAccount"]);
    XCTAssertTrue([filename hasSuffix:@".plist"]);
}

#pragma mark - setIdentityKeys:

- (void)test_setIdentityKeys_nonDefault_filtersToSupportedKeys {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1"];
    // "Identity" and "Email" are supported; "Custom" is not
    NSArray *keys = @[@"Identity", @"Email", @"Custom"];
    config.identityKeys = keys;
    XCTAssertTrue([config.identityKeys containsObject:@"Identity"]);
    XCTAssertTrue([config.identityKeys containsObject:@"Email"]);
    XCTAssertFalse([config.identityKeys containsObject:@"Custom"]);
}

- (void)test_setIdentityKeys_nonDefault_phoneIsSupported {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1"];
    NSArray *keys = @[@"Phone"];
    config.identityKeys = keys;
    XCTAssertTrue([config.identityKeys containsObject:@"Phone"]);
}

#pragma mark - setEncryptionLevel:

- (void)test_setEncryptionLevel_nonDefault_updatesLevel {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1"];
    [config setEncryptionLevel:CleverTapEncryptionMedium];
    XCTAssertEqual(config.encryptionLevel, CleverTapEncryptionMedium);
}

#pragma mark - setHandshakeDomain: / setEnableFileProtection: / setEncryptionInTransitEnabled:

- (void)test_setHandshakeDomain_nonDefault_updatesValue {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1"];
    config.handshakeDomain = @"handshake.example.com";
    XCTAssertEqualObjects(config.handshakeDomain, @"handshake.example.com");
}

- (void)test_setEnableFileProtection_nonDefault_updatesValue {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1"];
    config.enableFileProtection = YES;
    XCTAssertTrue(config.enableFileProtection);
}

- (void)test_setEncryptionInTransitEnabled_nonDefault_updatesValue {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1"];
    config.encryptionInTransitEnabled = YES;
    XCTAssertTrue(config.encryptionInTransitEnabled);
}

#pragma mark - copyWithZone:

- (void)test_copy_preservesAccountIdAndToken {
    CleverTapInstanceConfig *original = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1" accountRegion:@"eu1"];
    CleverTapInstanceConfig *copy = [original copy];
    XCTAssertEqualObjects(copy.accountId, original.accountId);
    XCTAssertEqualObjects(copy.accountToken, original.accountToken);
    XCTAssertEqualObjects(copy.accountRegion, original.accountRegion);
}

- (void)test_copy_returnsDistinctObject {
    CleverTapInstanceConfig *original = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1"];
    CleverTapInstanceConfig *copy = [original copy];
    XCTAssertFalse(copy == original);
}

- (void)test_copy_withProxyDomains_preservesThem {
    CleverTapInstanceConfig *original = [[CleverTapInstanceConfig alloc] initWithAccountId:@"acc1" accountToken:@"tok1" proxyDomain:@"proxy.example.com" spikyProxyDomain:@"spiky.example.com"];
    CleverTapInstanceConfig *copy = [original copy];
    XCTAssertEqualObjects(copy.proxyDomain, @"proxy.example.com");
    XCTAssertEqualObjects(copy.spikyProxyDomain, @"spiky.example.com");
}

#pragma mark - supportsSecureCoding

- (void)test_supportsSecureCoding_returnsYes {
    XCTAssertTrue([CleverTapInstanceConfig supportsSecureCoding]);
}

@end
