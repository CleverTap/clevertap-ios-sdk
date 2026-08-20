//
//  CTLoginInfoProviderTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTLoginInfoProvider.h"
#import "CTDeviceInfo.h"
#import "CleverTapInstanceConfig.h"

@interface CTLoginInfoProviderTest : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) CTLoginInfoProvider *provider;
@end

@implementation CTLoginInfoProviderTest

- (void)setUp {
    [super setUp];
    // Use a unique account ID so each test class run starts with a clean slate
    // in NSUserDefaults (no prior cached GUIDs or identities).
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"loginProviderTestAcct"
                                                        accountToken:@"testToken"];
    self.deviceInfo = [[CTDeviceInfo alloc] initWithConfig:self.config andCleverTapID:nil];
    self.provider = [[CTLoginInfoProvider alloc] initWithDeviceInfo:self.deviceInfo
                                                             config:self.config];
}

- (void)tearDown {
    // Clean up persisted state after each test
    [self.provider setCachedGUIDs:nil];
    [self.provider setCachedIdentities:nil];
    self.provider = nil;
    self.deviceInfo = nil;
    self.config = nil;
    [super tearDown];
}

#pragma mark - getCachedGUIDs / setCachedGUIDs

- (void)test_getCachedGUIDs_notSet_returnsNil {
    XCTAssertNil([self.provider getCachedGUIDs]);
}

- (void)test_setCachedGUIDs_getCachedGUIDs_roundTrip {
    NSDictionary *guids = @{@"Email_user@test.com": @"guid-abc"};
    [self.provider setCachedGUIDs:guids];
    XCTAssertEqualObjects([self.provider getCachedGUIDs], guids);
}

- (void)test_setCachedGUIDs_nilClears {
    [self.provider setCachedGUIDs:@{@"k": @"v"}];
    [self.provider setCachedGUIDs:nil];
    XCTAssertNil([self.provider getCachedGUIDs]);
}

#pragma mark - getCachedIdentities / setCachedIdentities

- (void)test_getCachedIdentities_notSet_returnsNil {
    XCTAssertNil([self.provider getCachedIdentities]);
}

- (void)test_setCachedIdentities_getCachedIdentities_roundTrip {
    [self.provider setCachedIdentities:@"Email,Identity"];
    XCTAssertEqualObjects([self.provider getCachedIdentities], @"Email,Identity");
}

- (void)test_setCachedIdentities_nilClears {
    [self.provider setCachedIdentities:@"Email"];
    [self.provider setCachedIdentities:nil];
    XCTAssertNil([self.provider getCachedIdentities]);
}

#pragma mark - isAnonymousDevice

- (void)test_isAnonymousDevice_noCache_returnsYes {
    XCTAssertTrue([self.provider isAnonymousDevice]);
}

- (void)test_isAnonymousDevice_withCachedGUIDs_returnsNo {
    [self.provider setCachedGUIDs:@{@"Email_user@test.com": @"guid-1"}];
    XCTAssertFalse([self.provider isAnonymousDevice]);
}

- (void)test_isAnonymousDevice_emptyDict_returnsYes {
    [self.provider setCachedGUIDs:@{}];
    XCTAssertTrue([self.provider isAnonymousDevice]);
}

#pragma mark - deviceIsMultiUser

- (void)test_deviceIsMultiUser_noCache_returnsNo {
    XCTAssertFalse([self.provider deviceIsMultiUser]);
}

- (void)test_deviceIsMultiUser_oneEntry_returnsNo {
    [self.provider setCachedGUIDs:@{@"Email_a@b.com": @"guid-1"}];
    XCTAssertFalse([self.provider deviceIsMultiUser]);
}

- (void)test_deviceIsMultiUser_twoEntries_returnsYes {
    [self.provider setCachedGUIDs:@{
        @"Email_a@b.com": @"guid-1",
        @"Identity_user1": @"guid-2"
    }];
    XCTAssertTrue([self.provider deviceIsMultiUser]);
}

#pragma mark - isLegacyProfileLoggedIn

- (void)test_isLegacyProfileLoggedIn_noCache_returnsNo {
    XCTAssertFalse([self.provider isLegacyProfileLoggedIn]);
}

- (void)test_isLegacyProfileLoggedIn_GUIDsWithoutIdentities_returnsYes {
    [self.provider setCachedGUIDs:@{@"Email_user@test.com": @"guid-1"}];
    // No cached identities → legacy user
    XCTAssertTrue([self.provider isLegacyProfileLoggedIn]);
}

- (void)test_isLegacyProfileLoggedIn_GUIDsAndIdentities_returnsNo {
    [self.provider setCachedGUIDs:@{@"Email_user@test.com": @"guid-1"}];
    [self.provider setCachedIdentities:@"Email"];
    XCTAssertFalse([self.provider isLegacyProfileLoggedIn]);
}

- (void)test_isLegacyProfileLoggedIn_identitiesWithoutGUIDs_returnsNo {
    [self.provider setCachedIdentities:@"Email"];
    XCTAssertFalse([self.provider isLegacyProfileLoggedIn]);
}

#pragma mark - removeValueFromCachedGUIDForKey:andGuid:

- (void)test_removeValueFromCachedGUID_matchingEntry_removesIt {
    [self.provider setCachedGUIDs:@{@"Email_user@test.com": @"guid-1"}];
    [self.provider removeValueFromCachedGUIDForKey:@"Email" andGuid:@"guid-1"];
    NSDictionary *remaining = [self.provider getCachedGUIDs];
    XCTAssertEqual(remaining.count, 0U);
}

- (void)test_removeValueFromCachedGUID_nonMatchingGUID_keepsEntry {
    [self.provider setCachedGUIDs:@{@"Email_user@test.com": @"guid-1"}];
    [self.provider removeValueFromCachedGUIDForKey:@"Email" andGuid:@"guid-OTHER"];
    NSDictionary *remaining = [self.provider getCachedGUIDs];
    XCTAssertEqual(remaining.count, 1U);
}

- (void)test_removeValueFromCachedGUID_nonMatchingKey_keepsEntry {
    [self.provider setCachedGUIDs:@{@"Email_user@test.com": @"guid-1"}];
    [self.provider removeValueFromCachedGUIDForKey:@"Identity" andGuid:@"guid-1"];
    NSDictionary *remaining = [self.provider getCachedGUIDs];
    XCTAssertEqual(remaining.count, 1U);
}

- (void)test_removeValueFromCachedGUID_emptyCache_doesNotCrash {
    XCTAssertNoThrow([self.provider removeValueFromCachedGUIDForKey:@"Email" andGuid:@"guid-1"]);
}

- (void)test_removeValueFromCachedGUID_leavesOtherEntries {
    [self.provider setCachedGUIDs:@{
        @"Email_user@test.com": @"guid-1",
        @"Identity_user1": @"guid-2"
    }];
    [self.provider removeValueFromCachedGUIDForKey:@"Email" andGuid:@"guid-1"];
    NSDictionary *remaining = [self.provider getCachedGUIDs];
    XCTAssertEqual(remaining.count, 1U);
    XCTAssertEqualObjects(remaining[@"Identity_user1"], @"guid-2");
}

@end
