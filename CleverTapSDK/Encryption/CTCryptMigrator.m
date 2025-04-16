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
        _cryptManager = [[CTEncryptionManager alloc] initWithAccountID:_config.accountId encryptionLevel:_config.encryptionLevel];
        if ([self isMigrationNeeded]) {
            [self performMigration];
        }
    }
    return self;
}

- (BOOL)isMigrationNeeded {
    self.lastEncryptionLevel = (CleverTapEncryptionLevel)[CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:kENCRYPTION_KEY accountID:_config.accountId]
                                                                      withResetValue:CleverTapEncryptionNone];
    
    long migrationDone = [CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_MIGRATION_STATUS accountID:_config.accountId]
                                       withResetValue:0];
    
    long encryptionDone = [CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_ALGORITHM accountID:_config.accountId]
                                        withResetValue:0];
    
    // If encryption is done, mark migration as complete and return
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
    
    BOOL isInAppDataMigrationSuccessful = [self migrateInAppData];
    if (!isInAppDataMigrationSuccessful) {
        migrationErrors = [migrationErrors stringByAppendingFormat:@"%@%@",
                           migrationErrors.length > 0 ? @", " : @"",
                           @"In-app data migration failed"];
    }
    
    if (isGUIDMigrationSuccessful && isUserProfileMigrationSuccessful && isInAppDataMigrationSuccessful) {
        [CTPreferences putInt:1 forKey:[CTUtils getKeyWithSuffix:CLTAP_ENCRYPTION_MIGRATION_STATUS accountID:_config.accountId]];
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
            NSString *partiallyDecryptedIdentifier = [_cryptManager decryptString:encryptedIdentifier encryptionAlgorithm:AES];
            NSString *decryptedIdentifier = [_cryptManager decryptString:partiallyDecryptedIdentifier encryptionAlgorithm:AES];

            if (decryptedIdentifier) {
                NSString *finalEncryptedIdentifier = decryptedIdentifier;
                
                if (_config.encryptionLevel == CleverTapEncryptionMedium) {
                    NSString *partiallyEncryptedIdentifier = [_cryptManager encryptString:decryptedIdentifier];
                    finalEncryptedIdentifier = [_cryptManager encryptString:partiallyEncryptedIdentifier];
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
    if (!keySuffix || keySuffix.length == 0) {
        CleverTapLogInfo(self.config.logLevel, @"Error: Key suffix is nil or empty.");
        return NO;
    }
    
    NSString *key = [self storageKeyWithSuffix:keySuffix];
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
        NSString *newStorageKey = [self storageKeyWithSuffix:keySuffix];
        [CTPreferences putString:migratedEncryptedString forKey:newStorageKey];
        
        CleverTapLogInfo(self.config.logLevel, @"GUID migration completed successfully for key: %@", keySuffix);
    } else {
        CleverTapLogInfo(self.config.logLevel, @"Value is already AES-GCM encrypted, no migration needed for key: %@", keySuffix);
    }

    return YES;
}

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", _config.accountId, _deviceInfo.deviceId, suffix];
}

#pragma mark - User Profile Migration

- (BOOL)migrateUserProfileData {
    NSString *profileFileName = [self profileFileName];
    
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
    
    NSMutableDictionary *updatedProfile = [self decryptOldPIIData:profile];
    
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

- (NSMutableDictionary *)decryptOldPIIData:(NSMutableDictionary *)profile {
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
            
            if (!decryptedString) {
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
