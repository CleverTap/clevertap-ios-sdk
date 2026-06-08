//
//  CTIdentityRepoFactoryTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTIdentityRepoFactory.h"
#import "CTLegacyIdentityRepo.h"
#import "CTFlexibleIdentityRepo.h"
#import "CTLoginInfoProvider.h"
#import "CTValidationResultStack.h"
#import "CTDeviceInfo.h"
#import "CleverTapInstanceConfig.h"

@interface CTIdentityRepoFactoryTest : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) CTValidationResultStack *validationResultStack;
@property (nonatomic, strong) CTLoginInfoProvider *loginInfoProvider;
@end

@implementation CTIdentityRepoFactoryTest

- (void)setUp {
    [super setUp];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"idRepoFactoryTestAcct"
                                                        accountToken:@"testToken"];
    self.deviceInfo = [[CTDeviceInfo alloc] initWithConfig:self.config andCleverTapID:nil];
    self.validationResultStack = [[CTValidationResultStack alloc] init];
    // Used to manipulate cached state before calling the factory
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

- (id<CTIdentityRepo>)makeRepo {
    return [CTIdentityRepoFactory getRepoForConfig:self.config
                                        deviceInfo:self.deviceInfo
                            validationResultStack:self.validationResultStack];
}

#pragma mark - fresh device → CTFlexibleIdentityRepo

- (void)test_freshDevice_returnsFlexibleIdentityRepo {
    // No cached GUIDs and no cached identities → not a legacy profile
    id<CTIdentityRepo> repo = [self makeRepo];
    XCTAssertTrue([repo isKindOfClass:[CTFlexibleIdentityRepo class]]);
}

- (void)test_freshDevice_repoIsNotNil {
    XCTAssertNotNil([self makeRepo]);
}

- (void)test_freshDevice_repoConformsToProtocol {
    id<CTIdentityRepo> repo = [self makeRepo];
    XCTAssertTrue([repo conformsToProtocol:@protocol(CTIdentityRepo)]);
}

#pragma mark - legacy profile → CTLegacyIdentityRepo

- (void)test_legacyProfile_returnsLegacyIdentityRepo {
    // Cached GUIDs with no cached identities = legacy user
    [self.loginInfoProvider setCachedGUIDs:@{@"Email_user@test.com": @"guid-abc"}];
    id<CTIdentityRepo> repo = [self makeRepo];
    XCTAssertTrue([repo isKindOfClass:[CTLegacyIdentityRepo class]]);
}

- (void)test_legacyProfile_repoIsNotNil {
    [self.loginInfoProvider setCachedGUIDs:@{@"Email_user@test.com": @"guid-abc"}];
    XCTAssertNotNil([self makeRepo]);
}

- (void)test_legacyProfile_repoConformsToProtocol {
    [self.loginInfoProvider setCachedGUIDs:@{@"Email_user@test.com": @"guid-abc"}];
    id<CTIdentityRepo> repo = [self makeRepo];
    XCTAssertTrue([repo conformsToProtocol:@protocol(CTIdentityRepo)]);
}

#pragma mark - GUIDs + identities → NOT legacy → CTFlexibleIdentityRepo

- (void)test_GUIDsAndIdentities_returnsFlexibleIdentityRepo {
    // Both cached GUIDs and identities → not legacy
    [self.loginInfoProvider setCachedGUIDs:@{@"Email_user@test.com": @"guid-abc"}];
    [self.loginInfoProvider setCachedIdentities:@"Email"];
    id<CTIdentityRepo> repo = [self makeRepo];
    XCTAssertTrue([repo isKindOfClass:[CTFlexibleIdentityRepo class]]);
}

#pragma mark - returned repo responds to protocol methods

- (void)test_flexibleRepo_respondsToGetIdentities {
    id<CTIdentityRepo> repo = [self makeRepo];
    XCTAssertTrue([repo respondsToSelector:@selector(getIdentities)]);
}

- (void)test_flexibleRepo_respondsToIsIdentity {
    id<CTIdentityRepo> repo = [self makeRepo];
    XCTAssertTrue([repo respondsToSelector:@selector(isIdentity:)]);
}

- (void)test_legacyRepo_getIdentitiesReturnsLegacyKeys {
    [self.loginInfoProvider setCachedGUIDs:@{@"Email_user@test.com": @"guid-abc"}];
    id<CTIdentityRepo> repo = [self makeRepo];
    NSArray *identities = [repo getIdentities];
    XCTAssertTrue([identities containsObject:@"Identity"]);
    XCTAssertTrue([identities containsObject:@"Email"]);
}

@end
