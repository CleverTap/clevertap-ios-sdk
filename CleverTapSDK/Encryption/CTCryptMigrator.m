#import <UIKit/UIKit.h>
#import "CTLocalDataStore.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTLoginInfoProvider.h"
#import "CTEncryptionManager.h"
#import "CTPreferences.h"
#import "CTUtils.h"
#import "CTCryptMigrator.h"

NSString *const kCachedGUIDSKey = @"CachedGUIDS";

@interface CTCryptMigrator()

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) NSArray *piiKeys;
@property (nonatomic, strong) CTEncryptionManager *cryptManager;
@property (nonatomic, assign) CleverTapEncryptionLevel lastEncryptionLevel;

@end

@implementation CTCryptMigrator

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                 andDeviceInfo:(CTDeviceInfo*)deviceInfo {
    if (self = [super init]) {
        _config = config;
        _deviceInfo = deviceInfo;
        _piiKeys = CLTAP_ENCRYPTION_PII_DATA;
        _cryptManager = [[CTEncryptionManager alloc] initWithAccountID:_config.accountId encryptionLevel:_config.encryptionLevel isDefaultInstance:YES];
        if ([self isMigrationNeeded]) {
            [self performMigration];
        }
    }
    return self;
}

- (BOOL)isMigrationNeeded {
    self.lastEncryptionLevel = (CleverTapEncryptionLevel)[CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:kENCRYPTION_KEY accountID:_config.accountId] withResetValue:CleverTapEncryptionNone];
    
    long migrationDone = [CTPreferences getIntForKey:CLTAP_ENCRYPTION_MIGRATION_STATUS withResetValue:0];
    
    if (_lastEncryptionLevel == CleverTapEncryptionMedium && migrationDone == 0){
        return YES;
    }
    
    return NO;
}

- (void)performMigration {
    NSString *migrationErrors = @"";
    
    BOOL isGUIDMigrationSuccessful = [self migrateGUIDS];
    if (!isGUIDMigrationSuccessful) {
        migrationErrors = [migrationErrors stringByAppendingFormat:@"%@%@",
                           migrationErrors.length > 0 ? @", " : @"",
                           @"GUID migration failed"];
    }
    
    BOOL isUserProfileMigrationSuccessful = [self migrateUserProfileData];
    if (!isUserProfileMigrationSuccessful) {
        migrationErrors = [migrationErrors stringByAppendingFormat:@"%@%@",
                           migrationErrors.length > 0 ? @", " : @"",
                           @"User profile migration failed"];
    }
    
    BOOL isInAppDataMigrationSuccessful = [self migrateInAppData];
    if (!isInAppDataMigrationSuccessful) {
        migrationErrors = [migrationErrors stringByAppendingFormat:@"%@%@",
                           migrationErrors.length > 0 ? @", " : @"",
                           @"In-app data migration failed"];
    }
    
    if (isGUIDMigrationSuccessful && isUserProfileMigrationSuccessful && isInAppDataMigrationSuccessful) {
        [CTPreferences putInt:1 forKey:CLTAP_ENCRYPTION_MIGRATION_STATUS];
        CleverTapLogDebug(_config.logLevel, @"%@: Migration completed successfully", self);
    } else {
        CleverTapLogDebug(_config.logLevel, @"%@: Migration failed: %@", self, migrationErrors);
    }
}

#pragma mark - GUID Migration

- (BOOL)migrateGUIDS {
    NSString *cacheKey = [CTUtils getKeyWithSuffix:kCachedGUIDSKey accountID:_config.accountId];
    NSDictionary *cachedGUIDS = [CTPreferences getObjectForKey:cacheKey];

    if (!cachedGUIDS || cachedGUIDS.count == 0) {
        CleverTapLogInfo(self.config.logLevel, @"No cached GUIDs found for migration.");
        return NO;
    }

    NSMutableDictionary *updatedCache = [NSMutableDictionary new];
    __block BOOL migrationSuccessful = NO;

    [cachedGUIDS enumerateKeysAndObjectsUsingBlock:^(NSString *cachedKey, NSString *value, BOOL *stop) {
        NSArray *components = [cachedKey componentsSeparatedByString:@"_"];
        if (components.count != 2) {
            CleverTapLogInfo(self.config.logLevel, @"Skipping invalid GUID format: %@", cachedKey);
            return;
        }

        NSString *key = components[0];
        NSString *encryptedIdentifier = components[1];

        if (encryptedIdentifier && ![_cryptManager isTextAESGCMEncrypted:encryptedIdentifier]) {
            NSString *decryptedIdentifier = [_cryptManager decryptString:encryptedIdentifier encryptionAlgorithm:AES];

            if (decryptedIdentifier) {
                NSString *finalEncryptedIdentifier = decryptedIdentifier;
                
                if (_config.encryptionLevel == CleverTapEncryptionMedium) {
                    finalEncryptedIdentifier = [_cryptManager encryptString:decryptedIdentifier];
                }

                updatedCache[[NSString stringWithFormat:@"%@_%@", key, finalEncryptedIdentifier]] = value;
                migrationSuccessful = YES;
            } else {
                CleverTapLogInfo(self.config.logLevel, @"Failed to decrypt GUID for key: %@", cachedKey);
            }
        }
    }];

    if (migrationSuccessful) {
        [CTPreferences putObject:updatedCache forKey:cacheKey];
        CleverTapLogInfo(self.config.logLevel, @"GUID migration completed successfully.");
        return YES;
    } else {
        CleverTapLogInfo(self.config.logLevel, @"GUID migration failed or no valid data to migrate.");
        return NO;
    }
}

#pragma mark - In-app Migration

- (BOOL)migrateInAppData {
    return ([self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY] &&
            [self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_CS] &&
            [self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_SS]);
}

- (BOOL)migrateInAppsWithKeySuffix:(NSString *)keySuffix {
    NSString *key = [self storageKeyWithSuffix:keySuffix];
    id value = [CTPreferences getObjectForKey:key];

    NSString *encryptedString = nil;
    if ([value isKindOfClass:[NSString class]]) {
        encryptedString = (NSString *)value;
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *arrayValue = (NSArray *)value;
        // Handle the array case appropriately, e.g., join into a string or take first value
        encryptedString = arrayValue.count > 0 ? [arrayValue firstObject] : nil;
    }
    
    if (encryptedString && ![_cryptManager isTextAESGCMEncrypted:encryptedString]) {
        NSArray *arr = [_cryptManager decryptObject:encryptedString encryptionAlgorithm:AES];
        if (arr) {
            NSString *migratedEncryptedString = [_cryptManager encryptObject:arr];
            [CTPreferences putString:migratedEncryptedString forKey:keySuffix];
        }
    }
    return YES;
}

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", _config.accountId, _deviceInfo.deviceId, suffix];
}

#pragma mark - User Profile Migration

- (BOOL)migrateUserProfileData {
    NSMutableDictionary *profile = (NSMutableDictionary *)[CTPreferences unarchiveFromFile:[self profileFileName] ofTypes:[NSSet setWithObjects:[NSArray class], [NSString class], [NSDictionary class], [NSNumber class], nil] removeFile:NO] ?: [NSMutableDictionary dictionary];
    NSMutableDictionary *updatedProfile = [self decryptOldPIIData:profile];
    [CTPreferences archiveObject:updatedProfile forFileName:[self profileFileName] config:self->_config];
    return YES;
}

- (NSMutableDictionary *)decryptOldPIIData:(NSMutableDictionary *)profile {
    long lastEncryptionLevel = [CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:kENCRYPTION_KEY accountID:self.config.accountId] withResetValue:0];
    
    if (lastEncryptionLevel == CleverTapEncryptionMedium && _cryptManager) {
        NSMutableDictionary *updatedProfile = [NSMutableDictionary new];
        for (NSString *key in profile) {
            NSString *value = [NSString stringWithFormat:@"%@", profile[key]];
            
            if ([_piiKeys containsObject:key] && value && ![_cryptManager isTextAESGCMEncrypted:value]) {
                NSString *decryptedString = [_cryptManager decryptString:value encryptionAlgorithm:AES];
                updatedProfile[key] = [_cryptManager encryptString:decryptedString];
            } else {
                updatedProfile[key] = profile[key];
            }
        }
        return updatedProfile;
    }
    return profile;
}

- (NSString *)profileFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-userprofile.plist", self.config.accountId, _deviceInfo.deviceId];
}

@end
