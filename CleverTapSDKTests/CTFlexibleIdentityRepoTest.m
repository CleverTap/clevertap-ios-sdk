//
//  CTFlexibleIdentityRepoTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTFlexibleIdentityRepo.h"
#import "CTLoginInfoProvider.h"
#import "CTValidationResultStack.h"
#import "CTDeviceInfo.h"
#import "CleverTapInstanceConfig.h"
#import "CTConstants.h"

@interface CTFlexibleIdentityRepoTest : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) CTValidationResultStack *validationResultStack;
@property (nonatomic, strong) CTLoginInfoProvider *loginInfoProvider;
@end

@implementation CTFlexibleIdentityRepoTest

- (void)setUp {
    [super setUp];
    // Non-default instance — identity keys come from config.identityKeys, not the plist.
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"flexIdRepoTestAcct"
                                                        accountToken:@"testToken"];
    self.deviceInfo = [[CTDeviceInfo alloc] initWithConfig:self.config andCleverTapID:nil];
    self.validationResultStack = [[CTValidationResultStack alloc] initWithConfig:self.config];
    self.loginInfoProvider = [[CTLoginInfoProvider alloc] initWithDeviceInfo:self.deviceInfo
                                                                      config:self.config];
}

- (void)tearDown {
    [self.loginInfoProvider setCachedGUIDs:nil];
    [self.loginInfoProvider setCachedIdentities:nil];
    self.loginInfoProvider = nil;
    self.validationResultStack = nil;
    self.deviceInfo = nil;
    self.config = nil;
    [super tearDown];
}

- (CTFlexibleIdentityRepo *)repoWithIdentityKeys:(NSArray *)keys {
    self.config.identityKeys = keys;
    return [[CTFlexibleIdentityRepo alloc] initWithConfig:self.config
                                               deviceInfo:self.deviceInfo
                                   validationResultStack:self.validationResultStack];
}

#pragma mark - getIdentities — config keys path (no cache)

- (void)test_getIdentities_configKeys_returnsConfigIdentifiers {
    CTFlexibleIdentityRepo *repo = [self repoWithIdentityKeys:@[@"Email", @"Phone"]];
    NSArray *identities = [repo getIdentities];
    XCTAssertTrue([identities containsObject:@"Email"]);
    XCTAssertTrue([identities containsObject:@"Phone"]);
}

- (void)test_getIdentities_configKeys_countMatchesConfig {
    CTFlexibleIdentityRepo *repo = [self repoWithIdentityKeys:@[@"Email", @"Phone"]];
    XCTAssertEqual([repo getIdentities].count, 2U);
}

- (void)test_getIdentities_noConfigKeys_usesDefaultConstants {
    CTFlexibleIdentityRepo *repo = [self repoWithIdentityKeys:nil];
    NSArray *identities = [repo getIdentities];
    // When config has no keys and no cache, falls back to CLTAP_PROFILE_IDENTIFIER_KEYS
    for (NSString *key in CLTAP_PROFILE_IDENTIFIER_KEYS) {
        XCTAssertTrue([identities containsObject:key], @"Expected default key '%@' in identities", key);
    }
}

- (void)test_getIdentities_emptyConfigKeys_usesDefaultConstants {
    CTFlexibleIdentityRepo *repo = [self repoWithIdentityKeys:@[]];
    NSArray *identities = [repo getIdentities];
    XCTAssertGreaterThan(identities.count, 0U);
}

#pragma mark - getIdentities — cached keys path

- (void)test_getIdentities_withCachedIdentities_usesCachedOnesFirst {
    // Pre-seed a cache with a different set than config
    [self.loginInfoProvider setCachedIdentities:@"Identity,Phone"];
    CTFlexibleIdentityRepo *repo = [self repoWithIdentityKeys:@[@"Email"]];
    NSArray *identities = [repo getIdentities];
    // Should use cached "Identity,Phone" split by comma
    XCTAssertTrue([identities containsObject:@"Identity"]);
    XCTAssertTrue([identities containsObject:@"Phone"]);
}

#pragma mark - isIdentity:

- (void)test_isIdentity_keyInConfig_returnsYes {
    CTFlexibleIdentityRepo *repo = [self repoWithIdentityKeys:@[@"Email", @"Phone"]];
    XCTAssertTrue([repo isIdentity:@"Email"]);
    XCTAssertTrue([repo isIdentity:@"Phone"]);
}

- (void)test_isIdentity_keyNotInConfig_returnsNo {
    CTFlexibleIdentityRepo *repo = [self repoWithIdentityKeys:@[@"Email"]];
    XCTAssertFalse([repo isIdentity:@"Identity"]);
}

- (void)test_isIdentity_emptyString_returnsNo {
    CTFlexibleIdentityRepo *repo = [self repoWithIdentityKeys:@[@"Email"]];
    XCTAssertFalse([repo isIdentity:@""]);
}

- (void)test_isIdentity_defaultKey_returnsYesWhenUsingDefaults {
    CTFlexibleIdentityRepo *repo = [self repoWithIdentityKeys:nil];
    // With no config keys or cache, repo loads CLTAP_PROFILE_IDENTIFIER_KEYS
    XCTAssertTrue([repo isIdentity:@"Identity"]);
    XCTAssertTrue([repo isIdentity:@"Email"]);
}

#pragma mark - mismatch pushes validation error

- (void)test_cachedIdentitiesMismatch_pushesValidationError {
    [self.loginInfoProvider setCachedIdentities:@"Email,Phone"];
    // Config has different keys → should push error 531
    CTFlexibleIdentityRepo *repo = [self repoWithIdentityKeys:@[@"Identity"]];
    XCTAssertNotNil(repo); // repo still initialises
    CTValidationResult *top = [self.validationResultStack popValidationResult];
    XCTAssertEqual(top.errorCode, 531);
}

@end
