#import <UIKit/UIKit.h>
#import "CTLocalDataStore.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTLoginInfoProvider.h"
#import "CTEncryptionManager.h"
#import "CTPreferences.h"
#import "CTUtils.h"
#import "CTCryptMigrator.h"

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
        _cryptManager = [[CTEncryptionManager alloc] initWithAccountID:_config.accountId encryptionLevel:_config.encryptionLevel];
        if ([self isInAppsMigrationNeeded]) {
            [self performMigrationForInApps];
        }
        if ([self isMigrationNeeded]) {
            [self performMigration];
        }
    }
    return self;
}

- (BOOL)isInAppsMigrationNeeded {
    // Check if InApps migration has already been done
    NSString *inAppsMigrationKey = [CTUtils getKeyWithSuffix:@"inapp_migration_done" accountID:_config.accountId];
    long inAppsMigrationDone = [CTPreferences getIntForKey:inAppsMigrationKey withResetValue:0];
    
    if (inAppsMigrationDone == 1) {
        return NO;
    }
    
    return YES;
}

- (void)performMigrationForInApps {
    NSString *inAppMigrationError = @"";
    BOOL isInAppDataMigrationSuccessful = [self migrateInAppData:nil];
    if (!isInAppDataMigrationSuccessful) {
        inAppMigrationError = [inAppMigrationError stringByAppendingFormat:@"%@%@",
                               inAppMigrationError.length > 0 ? @", " : @"",
                           @"In-app data migration failed"];
    }
    
    if (isInAppDataMigrationSuccessful) {
        CleverTapLogDebug(_config.logLevel, @"%@: inApp Migration completed successfully", self);
        
        // Mark InApps migration as done
        NSString *inAppsMigrationKey = [CTUtils getKeyWithSuffix:@"inapp_migration_done" accountID:_config.accountId];
        [CTPreferences putInt:1 forKey:inAppsMigrationKey];
    }
    else {
        CleverTapLogDebug(_config.logLevel, @"%@:inApp Migration failed: %@", self, inAppMigrationError);
    }
}

- (BOOL)isMigrationNeeded {
    self.lastEncryptionLevel = (CleverTapEncryptionLevel)[CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:kENCRYPTION_KEY accountID:_config.accountId]
                                                                      withResetValue:CleverTapEncryptionNone];
    
    long migrationDone = [CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_MIGRATION_STATUS accountID:_config.accountId]
                                       withResetValue:0];
    
    long encryptionDone = [CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_ALGORITHM accountID:_config.accountId]
                                        withResetValue:0];
    
    if (encryptionDone) {
        [CTPreferences putInt:1 forKey:[CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_MIGRATION_STATUS accountID:_config.accountId]];
        return NO;
    }
    
    if (_lastEncryptionLevel == CleverTapEncryptionMedium && migrationDone == 0)
        return YES;
    
    if (_lastEncryptionLevel == CleverTapEncryptionNone && migrationDone == 0) {
        [CTPreferences putInt:1 forKey:[CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_MIGRATION_STATUS accountID:_config.accountId]];
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
    
    if (isGUIDMigrationSuccessful && isUserProfileMigrationSuccessful) {
        [CTPreferences putInt:1 forKey:[CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_MIGRATION_STATUS accountID:_config.accountId]];
        CleverTapLogDebug(_config.logLevel, @"%@: Migration completed successfully", self);
    } else {
        CleverTapLogDebug(_config.logLevel, @"%@: Migration failed: %@", self, migrationErrors);
    }
}

#pragma mark - GUID Migration

- (BOOL)migrateGUIDS {
    NSString *cacheKey = [CTUtils getKeyWithSuffix:CLTAP_CachedGUIDSKey accountID:_config.accountId];
    NSDictionary *cachedGUIDS = [CTPreferences getObjectForKey:cacheKey];

    if (!cachedGUIDS || cachedGUIDS.count == 0) {
        CleverTapLogInfo(self.config.logLevel, @"No cached GUIDs found for migration.");
        return YES;
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
            NSString *partiallyDecryptedIdentifier = [_cryptManager decryptString:encryptedIdentifier encryptionAlgorithm:AES];
            NSString *decryptedIdentifier = nil;

            if (partiallyDecryptedIdentifier != nil) {
                decryptedIdentifier = [_cryptManager decryptString:partiallyDecryptedIdentifier encryptionAlgorithm:AES];
                
                if (decryptedIdentifier == nil || [decryptedIdentifier isEqual: @""]) {
                    decryptedIdentifier = partiallyDecryptedIdentifier;
                }
            }
            
            if (decryptedIdentifier) {
                NSString *finalEncryptedIdentifier = nil;
                
                if (_config.encryptionLevel == CleverTapEncryptionMedium) {
                    if ([decryptedIdentifier isEqualToString:partiallyDecryptedIdentifier]) {
                        finalEncryptedIdentifier = [_cryptManager encryptString:decryptedIdentifier];
                    } else {
                        NSString *partiallyEncryptedIdentifier = [_cryptManager encryptString:decryptedIdentifier];
                        finalEncryptedIdentifier = [_cryptManager encryptString:partiallyEncryptedIdentifier];
                    }
                } else {
                    finalEncryptedIdentifier = decryptedIdentifier;
                }

                updatedCache[[NSString stringWithFormat:@"%@_%@", key, finalEncryptedIdentifier]] = value;
                migrationSuccessful = YES;
            } else {
                [CTPreferences removeObjectForKey:cacheKey];
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

#pragma mark - In-App Data Migration

- (BOOL)migrateInAppData:(NSString *)deviceID {
    if (!deviceID) {
        deviceID = _deviceInfo.deviceId; // Use current device ID as fallback
    }
    
    return ([self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY deviceID:deviceID] &&
            [self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_CS deviceID:deviceID] &&
            [self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_SS deviceID:deviceID]);
}

// Unified method that handles both current and new device ID scenarios
- (BOOL)migrateInAppsWithKeySuffix:(NSString *)keySuffix deviceID:(NSString *)deviceID {
    
    NSString *key = [self inAppTypeWithSuffix:keySuffix deviceID:deviceID];
    if (!key) {
        CleverTapLogInfo(self.config.logLevel, @"Error: Failed to generate storage key.");
        return NO;
    }
    
    id value = [CTPreferences getObjectForKey:key];
    
    if (!value) {
        CleverTapLogInfo(self.config.logLevel, @"Warning: No value found for key: %@", key);
        return YES; // No value to migrate, but not a failure
    }

    NSString *encryptedString = nil;
    
    if ([value isKindOfClass:[NSString class]]) {
        encryptedString = (NSString *)value;
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *arrayValue = (NSArray *)value;
        if (arrayValue.count > 0 && [arrayValue.firstObject isKindOfClass:[NSString class]]) {
            encryptedString = arrayValue.firstObject;
        } else {
            CleverTapLogInfo(self.config.logLevel, @"Error: Array value is empty or contains non-string elements.");
            return NO;
        }
    } else {
        CleverTapLogInfo(self.config.logLevel, @"Error: Unsupported value type: %@", [value class]);
        return NO;
    }

    if (!encryptedString) {
        CleverTapLogInfo(self.config.logLevel, @"Error: Encrypted string is nil.");
        return NO;
    }

    if (![_cryptManager isTextAESGCMEncrypted:encryptedString]) {
        NSArray *arr = [_cryptManager decryptObject:encryptedString encryptionAlgorithm:AES];
        if (!arr) {
            CleverTapLogInfo(self.config.logLevel, @"Error: Decryption failed for string: %@", encryptedString);
            return NO;
        }
        
        NSString *migratedEncryptedString = [_cryptManager encryptObject:arr];
        if (!migratedEncryptedString) {
            CleverTapLogInfo(self.config.logLevel, @"Error: Encryption failed after decryption.");
            return NO;
        }
        
        // Here we use the current device ID for the new storage key
        NSString *newStorageKey = [self inAppTypeWithSuffix:keySuffix deviceID:deviceID];
        [CTPreferences putString:migratedEncryptedString forKey:newStorageKey];
        
        CleverTapLogInfo(self.config.logLevel, @"inApp migration completed successfully for key: %@", keySuffix);
    } else {
        CleverTapLogInfo(self.config.logLevel, @"Value is already AES-GCM encrypted, no migration needed for key: %@", keySuffix);
    }

    return YES;
}

- (NSString *)inAppTypeWithSuffix:(NSString *)suffix deviceID:(NSString *)deviceID {
    if (!deviceID) {
        deviceID = _deviceInfo.deviceId; // Use current device ID if not provided
    }
    return [NSString stringWithFormat:@"%@:%@:%@", _config.accountId, deviceID, suffix];
}

- (void)migrateCachedUserIfNeeded:(NSString *)newDeviceID {
    NSString *profileFileName = [NSString stringWithFormat:@"clevertap-%@-%@-userprofile.plist", self.config.accountId, newDeviceID];
    [self migrateInAppData:newDeviceID];
    [self migrateProfileWithFileName:profileFileName];
    return;
}

#pragma mark - User Profile Migration

- (BOOL)migrateUserProfileData {
    NSString *profileFileName = [self profileFileName];
    return [self migrateProfileWithFileName:profileFileName];
}

// Helper method containing the common migration logic
- (BOOL)migrateProfileWithFileName:(NSString *)profileFileName {
    if (!profileFileName || profileFileName.length == 0) {
        CleverTapLogInfo(self.config.logLevel, @"Error: Profile file name is nil or empty.");
        return NO;
    }
    
    NSMutableDictionary *profile = (NSMutableDictionary *)[CTPreferences unarchiveFromFile:profileFileName
                                                                                   ofTypes:[NSSet setWithObjects:[NSArray class], [NSString class], [NSDictionary class], [NSNumber class], nil]
                                                                                removeFile:NO];
    
    if (!profile) {
        CleverTapLogInfo(self.config.logLevel, @"Warning: No profile data found. Using empty dictionary.");
        profile = [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary *updatedProfile = [self decryptCachedPIIData:profile];
    
    if (!updatedProfile) {
        CleverTapLogInfo(self.config.logLevel, @"Error: Failed to decrypt or update profile data.");
        return NO;
    }
    
    BOOL success = [CTPreferences archiveObject:updatedProfile forFileName:profileFileName config:self->_config];
    
    if (!success) {
        CleverTapLogInfo(self.config.logLevel, @"Error: Failed to archive updated profile data.");
        return NO;
    }

    CleverTapLogInfo(self.config.logLevel, @"User profile data migration completed successfully.");
    return YES;
}

- (NSMutableDictionary *)decryptCachedPIIData:(NSMutableDictionary *)profile {
    if (!profile || profile.count == 0) {
        CleverTapLogInfo(self.config.logLevel, @"Warning: Profile dictionary is nil or empty. Skipping decryption.");
        return [NSMutableDictionary dictionary];
    }

    long lastEncryptionLevel = [CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:kENCRYPTION_KEY accountID:self.config.accountId] withResetValue:0];
    
    if (lastEncryptionLevel != CleverTapEncryptionMedium || !_cryptManager) {
        CleverTapLogInfo(self.config.logLevel, @"No decryption needed or CryptManager is nil.");
        return profile;
    }

    NSMutableDictionary *updatedProfile = [NSMutableDictionary new];

    for (NSString *key in profile) {
        if (![key isKindOfClass:[NSString class]]) {
            CleverTapLogInfo(self.config.logLevel, @"Error: Non-string key found in profile. Skipping.");
            continue;
        }

        NSString *value = [NSString stringWithFormat:@"%@", profile[key]];
        
        if ([_piiKeys containsObject:key] && value && ![_cryptManager isTextAESGCMEncrypted:value]) {
            NSString *decryptedString = [_cryptManager decryptString:value encryptionAlgorithm:AES];
            
            if (decryptedString == nil || [decryptedString isEqual: @""]) {
                CleverTapLogInfo(self.config.logLevel, @"Error: Decryption failed for key: %@", key);
                updatedProfile[key] = profile[key];
            } else {
                NSString *encryptedString = [_cryptManager encryptString:decryptedString];
                if (!encryptedString) {
                    CleverTapLogInfo(self.config.logLevel, @"Error: Re-encryption failed for key: %@", key);
                    updatedProfile[key] = profile[key];
                } else {
                    updatedProfile[key] = encryptedString;
                }
            }
        } else {
            updatedProfile[key] = profile[key];
        }
    }

    CleverTapLogInfo(self.config.logLevel, @"Decryption of old PII data completed successfully.");
    return updatedProfile;
}

- (NSString *)profileFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-userprofile.plist", self.config.accountId, _deviceInfo.deviceId];
}

@end
