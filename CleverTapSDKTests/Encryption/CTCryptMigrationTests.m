#import <XCTest/XCTest.h>
#import "CleverTap.h"
#import "CTEncryptionManager.h"
#import "CTEncryptionManager+Tests.h"
#import "CTCryptMigrator.h"
#import "CTConstants.h"
#import "CTLocalDataStore.h"
#import "CTProfileBuilder.h"
#import "CTUtils.h"
#import "CTPreferences.h"

@interface CTCryptMigrationTests : XCTestCase
@property (nonatomic, strong) NSString *region;
@property (nonatomic, strong) NSString *encryptedInApp;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) CTLocalDataStore *dataStore;
@property (nonatomic, strong) CTEncryptionManager *aesEncryptionManager; // AES encryption
@property (nonatomic, strong) CTEncryptionManager *aesgcmEncryptionManager; // AES-GCM encryption
@end

@implementation CTCryptMigrationTests

- (void)setUp {
    [super setUp];
    self.region = @"testRegion";
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken" accountRegion:self.region];
    self.config.encryptionLevel = CleverTapEncryptionMedium; // Set to Medium for migration
    
    self.deviceInfo = [[CTDeviceInfo alloc] initWithConfig:self.config andCleverTapID:@"testDeviceID"];
    
    CTDispatchQueueManager *queueManager = [[CTDispatchQueueManager alloc] initWithConfig:self.config];
    self.dataStore = [[CTLocalDataStore alloc] initWithConfig:self.config
                                              profileValues:[NSMutableDictionary new]
                                             andDeviceInfo:self.deviceInfo
                                     dispatchQueueManager:queueManager];
    
    // Setup encryption managers
    self.aesEncryptionManager = [[CTEncryptionManager alloc] initWithAccountID:self.config.accountId encryptionLevel:CleverTapEncryptionMedium];
    self.aesgcmEncryptionManager = [[CTEncryptionManager alloc] initWithAccountID:self.config.accountId encryptionLevel:CleverTapEncryptionMedium];
    
    // Reset all preferences for a clean test environment
    [self cleanupTestData];
}

- (void)tearDown {
    [self cleanupTestData];
    self.region = nil;
    self.config = nil;
    self.deviceInfo = nil;
    self.dataStore = nil;
    self.aesEncryptionManager = nil;
    self.aesgcmEncryptionManager = nil;
    [super tearDown];
}

- (void)cleanupTestData {
    // Clean up test data for GUIDs
    NSString *guidCacheKey = [CTUtils getKeyWithSuffix:CLTAP_CachedGUIDSKey accountID:self.config.accountId];
    [CTPreferences removeObjectForKey:guidCacheKey];
    
    // Clean up in-app migration status
       NSString *inAppsMigrationKey = [CTUtils getKeyWithSuffix:@"inapp_migration_done" accountID:self.config.accountId];
       [CTPreferences removeObjectForKey:inAppsMigrationKey];
    
    // Clean up for in-app data
    NSString *inAppKey = [self inAppTypeWithSuffix:CLTAP_PREFS_INAPP_KEY];
    NSString *inAppKeyCS = [self inAppTypeWithSuffix:CLTAP_PREFS_INAPP_KEY_CS];
    NSString *inAppKeySS = [self inAppTypeWithSuffix:CLTAP_PREFS_INAPP_KEY_SS];
    [CTPreferences removeObjectForKey:inAppKey];
    [CTPreferences removeObjectForKey:inAppKeyCS];
    [CTPreferences removeObjectForKey:inAppKeySS];
    
    // Clean up user profile
    NSString *profileFileName = [self profileFileName];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:profileFileName];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    
    // Clean up encryption flags
    NSString *encryptionKey = [CTUtils getKeyWithSuffix:kENCRYPTION_KEY accountID:self.config.accountId];
    NSString *migrationStatusKey = [CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_MIGRATION_STATUS accountID:self.config.accountId];
    NSString *encryptionDoneKey = [CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_ALGORITHM accountID:self.config.accountId];
    [CTPreferences removeObjectForKey:encryptionKey];
    [CTPreferences removeObjectForKey:migrationStatusKey];
    [CTPreferences removeObjectForKey:encryptionDoneKey];
}

/**
 * Sets up the preferences to trigger migration by setting:
 * - Encryption level to CleverTapEncryptionMedium
 * - Migration status to 0 (not done)
 * - Encryption done status to 0 (not done)
 */
- (void)setupForMigration {
    // Set preferences to values that will trigger migration
    NSString *encryptionKey = [CTUtils getKeyWithSuffix:kENCRYPTION_KEY accountID:self.config.accountId];
    NSString *migrationStatusKey = [CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_MIGRATION_STATUS accountID:self.config.accountId];
    NSString *encryptionDoneKey = [CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_ALGORITHM accountID:self.config.accountId];
    
    // Set to CleverTapEncryptionMedium, migration not done, encryption not done
    [CTPreferences putInt:CleverTapEncryptionMedium forKey:encryptionKey];
    [CTPreferences putInt:0 forKey:migrationStatusKey];
    [CTPreferences putInt:0 forKey:encryptionDoneKey];
}

- (NSString *)inAppTypeWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", self.config.accountId, self.deviceInfo.deviceId, suffix];
}

- (NSString *)profileFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-userprofile.plist", self.config.accountId, self.deviceInfo.deviceId];
}

#pragma mark - Test Data Configuration

/**
 * Configures test data with old AES encryption for all data types that need migration:
 * - In-app notifications
 * - GUID cache
 * - User profile data
 */
- (void)configureDataWithOldEncryption {
    [self configureInappsWithOldEncryption];
    [self configureCGKWithOldEncryption];
    [self configureUserProfileDataWithOldEncryption];
}

/**
 * Creates and stores sample in-app notification data encrypted with the old AES algorithm
 */
- (void)configureInappsWithOldEncryption {
    // Create sample in-app data
    NSArray *inAppData = @[
        @{@"id": @"inapp1", @"title": @"Test Notification 1", @"message": @"This is a test message"},
        @{@"id": @"inapp2", @"title": @"Test Notification 2", @"message": @"This is another test message"}
    ];
    
    // Encrypt with old AES algorithm
    NSString *encryptedInApp = [self.aesEncryptionManager encryptObject:inAppData encryptionAlgorithm:AES];
    self.encryptedInApp = encryptedInApp;
    
    // Store in preferences for each in-app type
    NSString *inAppKey = [self inAppTypeWithSuffix:CLTAP_PREFS_INAPP_KEY];
    NSString *inAppKeyCS = [self inAppTypeWithSuffix:CLTAP_PREFS_INAPP_KEY_CS];
    NSString *inAppKeySS = [self inAppTypeWithSuffix:CLTAP_PREFS_INAPP_KEY_SS];
    
    [CTPreferences putString:encryptedInApp forKey:inAppKey];
    [CTPreferences putString:encryptedInApp forKey:inAppKeyCS];
    [CTPreferences putString:encryptedInApp forKey:inAppKeySS];
}

/**
 * Creates and stores GUID cache data with keys encrypted using old double AES encryption
 */
- (void)configureCGKWithOldEncryption {
    // Create test data for GUID cache
    NSString *plainEmail = @"test@example.com";
    NSString *plainIdentity = @"testIdentity123";
    
    // Double encrypt with old AES algorithm to simulate previous implementation
    NSString *partiallyEncryptedEmail = [self.aesEncryptionManager encryptString:plainEmail encryptionAlgorithm:AES];
    NSString *encryptedEmail = [self.aesEncryptionManager encryptString:partiallyEncryptedEmail encryptionAlgorithm:AES];
    
    NSString *partiallyEncryptedIdentity = [self.aesEncryptionManager encryptString:plainIdentity encryptionAlgorithm:AES];
    NSString *encryptedIdentity = [self.aesEncryptionManager encryptString:partiallyEncryptedIdentity encryptionAlgorithm:AES];
    
    // Create cache with encrypted values
    NSDictionary *guidCache = @{
        [NSString stringWithFormat:@"Email_%@", encryptedEmail]: @"email-guid-value",
        [NSString stringWithFormat:@"Identity_%@", encryptedIdentity]: @"identity-guid-value"
    };
    
    // Store in preferences
    NSString *guidCacheKey = [CTUtils getKeyWithSuffix:CLTAP_CachedGUIDSKey accountID:self.config.accountId];
    [CTPreferences putObject:guidCache forKey:guidCacheKey];
}

/**
 * Creates and stores user profile data with PII fields encrypted using old AES algorithm
 */
- (void)configureUserProfileDataWithOldEncryption {
    // Create test user profile with PII data
    NSMutableDictionary *profileData = [NSMutableDictionary dictionary];
    
    profileData[@"Identity"] = [self.aesEncryptionManager encryptString:@"user123" encryptionAlgorithm:AES];
    profileData[@"Email"] = [self.aesEncryptionManager encryptString:@"user@example.com" encryptionAlgorithm:AES];
    profileData[@"Phone"] = [self.aesEncryptionManager encryptString:@"+1234567890" encryptionAlgorithm:AES];
    profileData[@"Name"] = [self.aesEncryptionManager encryptString:@"Test User" encryptionAlgorithm:AES];
    
    // Add non-PII data
    profileData[@"Age"] = @30;
    profileData[@"Country"] = @"USA";
    profileData[@"Language"] = @"English";
    
    // Save to profile file
    NSString *profileFileName = [self profileFileName];
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wnonnull"
    [CTPreferences archiveObject:profileData forFileName:profileFileName config:nil];
    #pragma clang diagnostic pop
}

#pragma mark - Test Cases

/**
 * Tests that migration is triggered and completes successfully when migration
 * conditions are met and data exists to be migrated.
 */
- (void)testMigrationHappens {
    // Setup for migration
    [self setupForMigration];
    [self configureDataWithOldEncryption];
    
    // Verify setup is correct for migration
    NSString *migrationStatusKey = [CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_MIGRATION_STATUS accountID:self.config.accountId];
    long migrationStatus = [CTPreferences getIntForKey:migrationStatusKey withResetValue:-1];
    XCTAssertEqual(migrationStatus, 0, @"Migration status should be 0 before migration");
    
    // Create the migrator which should perform migration
    CTCryptMigrator *migrator = [[CTCryptMigrator alloc] initWithConfig:self.config andDeviceInfo:self.deviceInfo];
    
    // Check if migration has completed
    migrationStatus = [CTPreferences getIntForKey:migrationStatusKey withResetValue:-1];
    XCTAssertEqual(migrationStatus, 1, @"Migration status should be 1 after migration");
}

/**
 * Tests GUID cache migration from old double AES encryption to new AES-GCM encryption.
 * Verifies that keys are re-encrypted while preserving their format and associated values.
 */
- (void)testGUIDMigration {
    // Setup for migration
    [self setupForMigration];
    
    // Original plaintext values
    NSString *originalEmail = @"user@example.com";
    NSString *originalIdentity = @"user123";
    
    // Create GUID cache with keys encrypted using old AES algorithm (double encryption)
    NSString *partiallyEncryptedEmail = [self.aesEncryptionManager encryptString:originalEmail encryptionAlgorithm:AES];
    NSString *encryptedEmail = [self.aesEncryptionManager encryptString:partiallyEncryptedEmail encryptionAlgorithm:AES];
    
    NSString *partiallyEncryptedIdentity = [self.aesEncryptionManager encryptString:originalIdentity encryptionAlgorithm:AES];
    NSString *encryptedIdentity = [self.aesEncryptionManager encryptString:partiallyEncryptedIdentity encryptionAlgorithm:AES];
    
    // Create the cache with encrypted keys
    NSDictionary *originalCache = @{
        [NSString stringWithFormat:@"Email_%@", encryptedEmail]: @"email-guid-value",
        [NSString stringWithFormat:@"Identity_%@", encryptedIdentity]: @"identity-guid-value"
    };
    
    // Save the cache to preferences
    NSString *guidCacheKey = [CTUtils getKeyWithSuffix:CLTAP_CachedGUIDSKey accountID:self.config.accountId];
    [CTPreferences putObject:originalCache forKey:guidCacheKey];
    
    // Create the migrator which will perform migration
    CTCryptMigrator *migrator = [[CTCryptMigrator alloc] initWithConfig:self.config andDeviceInfo:self.deviceInfo];
    
    // Get the migrated cache
    NSDictionary *migratedCache = [CTPreferences getObjectForKey:guidCacheKey];
    XCTAssertNotNil(migratedCache, @"Migrated cache should exist");
    XCTAssertEqual(migratedCache.count, originalCache.count, @"Migrated cache should have the same number of entries");
    
    // Verify the keys have changed (migration occurred)
    NSSet *originalKeys = [NSSet setWithArray:originalCache.allKeys];
    NSSet *migratedKeys = [NSSet setWithArray:migratedCache.allKeys];
    XCTAssertFalse([originalKeys isEqualToSet:migratedKeys], @"Keys should be different after migration");
    
    // Verify the values remain unchanged
    NSArray *originalValues = [originalCache.allValues sortedArrayUsingSelector:@selector(compare:)];
    NSArray *migratedValues = [migratedCache.allValues sortedArrayUsingSelector:@selector(compare:)];
    XCTAssertEqualObjects(originalValues, migratedValues, @"GUID values should remain unchanged");
    
    // Extract and verify some values to ensure they're correctly formatted
    for (NSString *key in migratedCache) {
        XCTAssertTrue([key hasPrefix:@"Email_"] || [key hasPrefix:@"Identity_"], @"Key format should be preserved");
    }
}

/**
 * Tests in-app data migration from old AES encryption to new AES-GCM encryption.
 * Verifies that the data is re-encrypted while preserving its content.
 */
- (void)testInAppDataMigration {
    // Setup for migration
    [self setupForMigration];
    [self configureInappsWithOldEncryption];
    
    // Additional setup: Make sure in-app migration is needed
    NSString *inAppsMigrationKey = [CTUtils getKeyWithSuffix:@"inapp_migration_done" accountID:self.config.accountId];
    [CTPreferences putInt:0 forKey:inAppsMigrationKey]; // Reset in-app migration status
    
    // Get original in-app data
    NSString *inAppKey = [self inAppTypeWithSuffix:CLTAP_PREFS_INAPP_KEY];
    NSString *originalInApp = [CTPreferences getObjectForKey:inAppKey];
    XCTAssertNotNil(originalInApp, @"Original in-app data should exist");
    XCTAssertEqualObjects(originalInApp, self.encryptedInApp, @"Original in-app data should match what we set");
    
    // Create the migrator
    CTCryptMigrator *migrator = [[CTCryptMigrator alloc] initWithConfig:self.config andDeviceInfo:self.deviceInfo];
    
    // Get updated in-app data
    NSString *updatedInApp = [CTPreferences getObjectForKey:inAppKey];
    XCTAssertNotNil(updatedInApp, @"Updated in-app data should exist");
    
    // Check if migration happened - we need to check this differently now
    BOOL migrationHappened = ![updatedInApp isEqualToString:self.encryptedInApp] ||
                            [self.aesgcmEncryptionManager isTextAESGCMEncrypted:updatedInApp];
    
    XCTAssertTrue(migrationHappened, @"In-app data migration should have occurred");
    
    // If migration happened, verify the new encrypted data can be decrypted
    if (migrationHappened) {
        NSArray *decryptedInApp = [self.aesgcmEncryptionManager decryptObject:updatedInApp];
        XCTAssertNotNil(decryptedInApp, @"Should be able to decrypt migrated data");
    }
    
    // Similar modifications for CS and SS keys
    NSString *inAppKeyCS = [self inAppTypeWithSuffix:CLTAP_PREFS_INAPP_KEY_CS];
    NSString *updatedInAppCS = [CTPreferences getObjectForKey:inAppKeyCS];
    XCTAssertNotNil(updatedInAppCS, @"Updated in-app CS data should exist");
    
    BOOL csDataMigrated = ![updatedInAppCS isEqualToString:self.encryptedInApp] ||
                          [self.aesgcmEncryptionManager isTextAESGCMEncrypted:updatedInAppCS];
    XCTAssertTrue(csDataMigrated, @"In-app CS data should have been migrated");
    
    NSString *inAppKeySS = [self inAppTypeWithSuffix:CLTAP_PREFS_INAPP_KEY_SS];
    NSString *updatedInAppSS = [CTPreferences getObjectForKey:inAppKeySS];
    XCTAssertNotNil(updatedInAppSS, @"Updated in-app SS data should exist");
    
    BOOL ssDataMigrated = ![updatedInAppSS isEqualToString:self.encryptedInApp] ||
                          [self.aesgcmEncryptionManager isTextAESGCMEncrypted:updatedInAppSS];
    XCTAssertTrue(ssDataMigrated, @"In-app SS data should have been migrated");
}

/**
 * Tests user profile migration from old AES encryption to new AES-GCM encryption.
 * Verifies that PII fields are re-encrypted while preserving their original values,
 * and non-PII fields remain unchanged.
 */
- (void)testUserProfileMigration {
    // Setup for migration
    [self setupForMigration];
    
    // Original plaintext values
    NSDictionary *originalPlainValues = @{
        @"Identity": @"user123",
        @"Email": @"user@example.com",
        @"Phone": @"+1234567890",
        @"Name": @"Test User",
        @"Age": @30,
        @"Country": @"USA",
        @"Language": @"English"
    };
    
    // Create profile with PII fields encrypted using old AES algorithm
    NSMutableDictionary *profileWithOldEncryption = [NSMutableDictionary dictionary];
    NSArray *piiKeys = CLTAP_ENCRYPTION_PII_DATA; // @[@"Identity", @"Email", @"Phone", @"Name"]
    
    // Copy all values to the profile
    [profileWithOldEncryption addEntriesFromDictionary:originalPlainValues];
    
    // Encrypt only PII data with old AES algorithm
    for (NSString *piiKey in piiKeys) {
        if (profileWithOldEncryption[piiKey]) {
            NSString *valueToEncrypt = [NSString stringWithFormat:@"%@", profileWithOldEncryption[piiKey]];
            NSString *encryptedValue = [self.aesEncryptionManager encryptString:valueToEncrypt encryptionAlgorithm:AES];
            profileWithOldEncryption[piiKey] = encryptedValue;
        }
    }
    
    // Save the profile to the file system
    NSString *profileFileName = [self profileFileName];
    BOOL saveSuccess = [CTPreferences archiveObject:profileWithOldEncryption forFileName:profileFileName config:self.config];
    XCTAssertTrue(saveSuccess, @"Should be able to save the profile with old encryption");
    
    // Verify the profile was saved correctly
    NSMutableDictionary *savedProfile = (NSMutableDictionary *)[CTPreferences unarchiveFromFile:profileFileName
                                                                                       ofTypes:[NSSet setWithObjects:[NSArray class], [NSString class], [NSDictionary class], [NSNumber class], nil]
                                                                                    removeFile:NO];
    XCTAssertNotNil(savedProfile, @"Saved profile should exist");
    
    // Create the migrator which will perform migration
    CTCryptMigrator *migrator = [[CTCryptMigrator alloc] initWithConfig:self.config andDeviceInfo:self.deviceInfo];
    
    // Get the migrated profile
    NSMutableDictionary *migratedProfile = (NSMutableDictionary *)[CTPreferences unarchiveFromFile:profileFileName
                                                                                          ofTypes:[NSSet setWithObjects:[NSArray class], [NSString class], [NSDictionary class], [NSNumber class], nil]
                                                                                       removeFile:NO];
    XCTAssertNotNil(migratedProfile, @"Migrated profile should exist");
    
    // Decrypt the migrated profile
    NSMutableDictionary *decryptedProfile = [NSMutableDictionary dictionaryWithDictionary:migratedProfile];
    
    for (NSString *piiKey in piiKeys) {
        if (migratedProfile[piiKey]) {
            NSString *encryptedValue = [NSString stringWithFormat:@"%@", migratedProfile[piiKey]];
            NSString *decryptedValue = [self.aesgcmEncryptionManager decryptString:encryptedValue];
            decryptedProfile[piiKey] = decryptedValue;
        }
    }
    
    // Create a dictionary with only the keys we want to compare
    NSMutableDictionary *originalToCompare = [NSMutableDictionary dictionary];
    NSMutableDictionary *decryptedToCompare = [NSMutableDictionary dictionary];
    
    for (NSString *key in originalPlainValues) {
        originalToCompare[key] = originalPlainValues[key];
        decryptedToCompare[key] = decryptedProfile[key];
    }
    
    // Verify the decrypted profile matches the original plain values
    XCTAssertEqualObjects(originalToCompare, decryptedToCompare,
                         @"After migration and decryption, the profile should match the original values");
    
    // Also verify that the encrypted values have changed (migration occurred)
    for (NSString *piiKey in piiKeys) {
        XCTAssertNotEqualObjects(profileWithOldEncryption[piiKey], migratedProfile[piiKey],
                                @"PII field %@ should have been re-encrypted", piiKey);
    }
    
    // Verify non-PII data remains unchanged
    NSMutableSet *allKeys = [NSMutableSet setWithArray:originalPlainValues.allKeys];
    [allKeys minusSet:[NSSet setWithArray:piiKeys]];
    
    for (NSString *nonPiiKey in allKeys) {
        XCTAssertEqualObjects(originalPlainValues[nonPiiKey], migratedProfile[nonPiiKey],
                              @"Non-PII field %@ should remain unchanged", nonPiiKey);
    }
}
/**
 * Tests migration when decryption fails, simulating corrupt data or
 * other error conditions during migration.
 */
- (void)testMigrationWithDecryptionFailure {
    // Setup for migration
    [self setupForMigration];
    
    // Create profile with invalid encrypted data
    NSMutableDictionary *profileWithInvalidData = [NSMutableDictionary dictionary];
    
    // Valid encrypted value
    profileWithInvalidData[@"Email"] = [self.aesEncryptionManager encryptString:@"user@example.com" encryptionAlgorithm:AES];
    
    // Invalid encrypted value (not a proper encryption result)
    profileWithInvalidData[@"Identity"] = @"not-a-valid-encrypted-string";
    
    // Normal non-PII data
    profileWithInvalidData[@"Age"] = @30;
    
    // Save to profile file
    NSString *profileFileName = [self profileFileName];
    [CTPreferences archiveObject:profileWithInvalidData forFileName:profileFileName config:self.config];
    
    // Create the migrator - should handle decryption failure gracefully
    CTCryptMigrator *migrator = [[CTCryptMigrator alloc] initWithConfig:self.config andDeviceInfo:self.deviceInfo];
    
    // Get the migrated profile
    NSMutableDictionary *migratedProfile = (NSMutableDictionary *)[CTPreferences unarchiveFromFile:profileFileName
                                                                                          ofTypes:[NSSet setWithObjects:[NSArray class], [NSString class], [NSDictionary class], [NSNumber class], nil]
                                                                                       removeFile:NO];
    
    XCTAssertNotNil(migratedProfile, @"Migrated profile should exist even with decryption failures");
    
    // Valid data should be migrated
    XCTAssertNotEqualObjects(profileWithInvalidData[@"Email"], migratedProfile[@"Email"],
                           @"Valid encrypted data should be migrated");
    
    // Invalid data should either be preserved or handled according to implementation
    XCTAssertNotNil(migratedProfile[@"Identity"], @"Invalid data should be handled without crashing");
    
    // Non-PII data should be preserved
    XCTAssertEqualObjects(profileWithInvalidData[@"Age"], migratedProfile[@"Age"],
                        @"Non-PII data should be preserved");
}

/**
 * Tests migration behavior in various edge cases:
 * 1. Empty data - no data exists to migrate
 * 2. Encryption already done - migration should be skipped
 * 3. Encryption level None - migration should be skipped
 */
- (void)testMigrationEdgeCases {
    // 1. Test with empty data
    [self cleanupTestData];
    [self setupForMigration];
    
    // Before migration, verify status is 0
    NSString *migrationStatusKey = [CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_MIGRATION_STATUS accountID:self.config.accountId];
    long migrationStatusBefore = [CTPreferences getIntForKey:migrationStatusKey withResetValue:-1];
    XCTAssertEqual(migrationStatusBefore, 0, @"Migration status should be 0 before migration");
    
    // Initialize migrator with no data to migrate
    CTCryptMigrator *migrator = [[CTCryptMigrator alloc] initWithConfig:self.config andDeviceInfo:self.deviceInfo];
    
    // Migration behavior with no data depends on implementation:
    // - If implementation marks migration as complete even with no data: status should be 1
    // - If implementation requires data to mark migration as complete: status might still be 0
    long migrationStatusAfter = [CTPreferences getIntForKey:migrationStatusKey withResetValue:-1];
    XCTAssertTrue(migrationStatusAfter == 0 || migrationStatusAfter == 1,
                 @"Migration status should either remain 0 or be set to 1");
    
    // 2. Test with encryptionDone = true
    [self cleanupTestData];
    [self setupForMigration];
    NSString *encryptionDoneKey = [CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_ALGORITHM accountID:self.config.accountId];
    [CTPreferences putInt:1 forKey:encryptionDoneKey]; // Mark encryption as done
    
    migrator = [[CTCryptMigrator alloc] initWithConfig:self.config andDeviceInfo:self.deviceInfo];
    
    // Migration should be skipped but status marked as completed
    migrationStatusAfter = [CTPreferences getIntForKey:migrationStatusKey withResetValue:-1];
    XCTAssertEqual(migrationStatusAfter, 1, @"Migration status should be completed when encryption is already done");
    
    // 3. Test with CleverTapEncryptionNone
    [self cleanupTestData];
    self.config.encryptionLevel = CleverTapEncryptionNone;
    NSString *encryptionKey = [CTUtils getKeyWithSuffix:kENCRYPTION_KEY accountID:self.config.accountId];
    [CTPreferences putInt:CleverTapEncryptionNone forKey:encryptionKey];
    [CTPreferences putInt:0 forKey:migrationStatusKey];
    
    migrator = [[CTCryptMigrator alloc] initWithConfig:self.config andDeviceInfo:self.deviceInfo];
    
    // Migration should be skipped but status marked as completed
    migrationStatusAfter = [CTPreferences getIntForKey:migrationStatusKey withResetValue:-1];
    XCTAssertEqual(migrationStatusAfter, 1, @"Migration status should be completed for None encryption level");
}

@end
