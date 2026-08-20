//
//  CTInAppFCManagerLegacyTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTInAppFCManager+Legacy.h"
#import "CTPreferences.h"
#import "CTConstants.h"
#import "InAppHelper.h"

@interface CTInAppFCManagerLegacyTest : XCTestCase
@property (nonatomic, strong) InAppHelper *helper;
@property (nonatomic, strong) CTInAppFCManager *fcManager;
// Old key format: "accountId:suffix"
@property (nonatomic, copy) NSString *oldLastDateKey;
@property (nonatomic, copy) NSString *oldCountShownKey;
@property (nonatomic, copy) NSString *oldCountPerInAppKey;
// New key format: "accountId:suffix:deviceId"
@property (nonatomic, copy) NSString *theNewLastDateKey;
@property (nonatomic, copy) NSString *theNewCountShownKey;
@property (nonatomic, copy) NSString *theNewCountPerInAppKey;
// Default config key and its migrated form: "suffix:deviceId"
@property (nonatomic, copy) NSString *defaultCountPerInAppKey;
@property (nonatomic, copy) NSString *defaultCountPerInAppMigratedKey;
@end

@implementation CTInAppFCManagerLegacyTest

- (void)setUp {
    [super setUp];
    self.helper = [InAppHelper new];
    self.fcManager = self.helper.inAppFCManager;

    NSString *accountId = self.helper.accountId;
    NSString *deviceId  = self.helper.deviceId;

    self.oldLastDateKey   = [NSString stringWithFormat:@"%@:%@", accountId, CLTAP_PREFS_INAPP_LAST_DATE_KEY];
    self.oldCountShownKey = [NSString stringWithFormat:@"%@:%@", accountId, CLTAP_PREFS_INAPP_COUNTS_SHOWN_TODAY_KEY];
    self.oldCountPerInAppKey = [NSString stringWithFormat:@"%@:%@", accountId, CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY];

    self.theNewLastDateKey   = [NSString stringWithFormat:@"%@:%@:%@", accountId, CLTAP_PREFS_INAPP_LAST_DATE_KEY, deviceId];
    self.theNewCountShownKey = [NSString stringWithFormat:@"%@:%@:%@", accountId, CLTAP_PREFS_INAPP_COUNTS_SHOWN_TODAY_KEY, deviceId];
    self.theNewCountPerInAppKey = [NSString stringWithFormat:@"%@:%@:%@", accountId, CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY, deviceId];

    self.defaultCountPerInAppKey        = CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY;
    self.defaultCountPerInAppMigratedKey = [NSString stringWithFormat:@"%@:%@", CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY, deviceId];

    // FCManager initialization may pre-populate the new-format keys with default values.
    // Clear them so that "noOldKey" tests start with a clean slate.
    [CTPreferences removeObjectForKey:self.theNewLastDateKey];
    [CTPreferences removeObjectForKey:self.theNewCountShownKey];
    [CTPreferences removeObjectForKey:self.theNewCountPerInAppKey];
}

- (void)tearDown {
    // Remove all keys touched by migration tests
    [CTPreferences removeObjectForKey:self.oldLastDateKey];
    [CTPreferences removeObjectForKey:self.theNewLastDateKey];
    [CTPreferences removeObjectForKey:self.oldCountShownKey];
    [CTPreferences removeObjectForKey:self.theNewCountShownKey];
    [CTPreferences removeObjectForKey:self.oldCountPerInAppKey];
    [CTPreferences removeObjectForKey:self.theNewCountPerInAppKey];
    [CTPreferences removeObjectForKey:self.defaultCountPerInAppKey];
    [CTPreferences removeObjectForKey:self.defaultCountPerInAppMigratedKey];
    self.fcManager = nil;
    self.helper = nil;
    [super tearDown];
}

#pragma mark - lastUpdateKeyChanges

- (void)test_migrate_lastDate_movesValueToNewKey {
    [CTPreferences putString:@"20240101" forKey:self.oldLastDateKey];
    [self.fcManager migratePreferenceKeys];
    NSString *migrated = [CTPreferences getStringForKey:self.theNewLastDateKey withResetValue:nil];
    XCTAssertEqualObjects(migrated, @"20240101");
}

- (void)test_migrate_lastDate_removesOldKey {
    [CTPreferences putString:@"20240101" forKey:self.oldLastDateKey];
    [self.fcManager migratePreferenceKeys];
    NSString *remaining = [CTPreferences getStringForKey:self.oldLastDateKey withResetValue:nil];
    XCTAssertNil(remaining);
}

- (void)test_migrate_lastDate_noOldKey_doesNotModifyNewKey {
    // Nothing seeded — new key must not be created
    [self.fcManager migratePreferenceKeys];
    NSString *value = [CTPreferences getStringForKey:self.theNewLastDateKey withResetValue:nil];
    XCTAssertNil(value);
}

#pragma mark - countShownTodayKeyChanges

- (void)test_migrate_countShownToday_movesValueToNewKey {
    [CTPreferences putInt:5 forKey:self.oldCountShownKey];
    [self.fcManager migratePreferenceKeys];
    int migrated = (int)[CTPreferences getIntForKey:self.theNewCountShownKey withResetValue:0];
    XCTAssertEqual(migrated, 5);
}

- (void)test_migrate_countShownToday_removesOldKey {
    [CTPreferences putInt:5 forKey:self.oldCountShownKey];
    [self.fcManager migratePreferenceKeys];
    XCTAssertNil([CTPreferences getObjectForKey:self.oldCountShownKey]);
}

- (void)test_migrate_countShownToday_noOldKey_doesNotModifyNewKey {
    [self.fcManager migratePreferenceKeys];
    XCTAssertNil([CTPreferences getObjectForKey:self.theNewCountShownKey]);
}

- (void)test_migrate_countShownToday_wrongType_doesNotMigrate {
    // Store a non-NSNumber value — migration should skip it
    [CTPreferences putString:@"notANumber" forKey:self.oldCountShownKey];
    [self.fcManager migratePreferenceKeys];
    XCTAssertNil([CTPreferences getObjectForKey:self.theNewCountShownKey]);
}

#pragma mark - countPerInAppKeyChanges

- (void)test_migrate_countPerInApp_movesValueToNewKey {
    NSDictionary *counts = @{@"camp1": @3, @"camp2": @1};
    [CTPreferences putObject:counts forKey:self.oldCountPerInAppKey];
    [self.fcManager migratePreferenceKeys];
    NSDictionary *migrated = [CTPreferences getObjectForKey:self.theNewCountPerInAppKey];
    XCTAssertEqualObjects(migrated, counts);
}

- (void)test_migrate_countPerInApp_removesOldKey {
    [CTPreferences putObject:@{@"camp1": @1} forKey:self.oldCountPerInAppKey];
    [self.fcManager migratePreferenceKeys];
    XCTAssertNil([CTPreferences getObjectForKey:self.oldCountPerInAppKey]);
}

- (void)test_migrate_countPerInApp_noOldKey_doesNotModifyNewKey {
    [self.fcManager migratePreferenceKeys];
    XCTAssertNil([CTPreferences getObjectForKey:self.theNewCountPerInAppKey]);
}

#pragma mark - countPerInAppKeyChangesForDefaultConfig

- (void)test_migrate_defaultCountPerInApp_movesToDeviceIdKey {
    NSDictionary *counts = @{@"camp_x": @2};
    [CTPreferences putObject:counts forKey:self.defaultCountPerInAppKey];
    [self.fcManager migratePreferenceKeys];
    NSDictionary *migrated = [CTPreferences getObjectForKey:self.defaultCountPerInAppMigratedKey];
    XCTAssertEqualObjects(migrated, counts);
}

- (void)test_migrate_defaultCountPerInApp_removesDefaultKey {
    [CTPreferences putObject:@{@"camp_x": @2} forKey:self.defaultCountPerInAppKey];
    [self.fcManager migratePreferenceKeys];
    XCTAssertNil([CTPreferences getObjectForKey:self.defaultCountPerInAppKey]);
}

- (void)test_migrate_defaultCountPerInApp_noOldKey_doesNotCreateMigratedKey {
    [self.fcManager migratePreferenceKeys];
    XCTAssertNil([CTPreferences getObjectForKey:self.defaultCountPerInAppMigratedKey]);
}

@end
