#import <UIKit/UIKit.h>
#import "CTLocalDataStore.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTLoginInfoProvider.h"
#import "CTEncryptionManager.h"
#import "CTPreferences.h"
#import "CTUtils.h"
#import "CTCryptMigrator.h"

NSString *const CT_DECRYPTION_KEY = @"CLTAP_ENCRYPTION_KEY";
NSString *const kCachedGUIDSKey = @"CachedGUIDS";

@interface CTCryptMigrator()

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) NSArray *piiKeys;
@property (nonatomic, strong) CTEncryptionManager *cryptManager;

@end

@implementation CTCryptMigrator

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                 andDeviceInfo:(CTDeviceInfo*)deviceInfo {
    if (self = [super init]) {
        _config = config;
        _deviceInfo = deviceInfo;
        _piiKeys = CLTAP_ENCRYPTION_PII_DATA;
        _cryptManager = [[CTEncryptionManager alloc] initWithAccountID:_config.accountId];
        if ([self isMigrationNeeded]) {
            [self performMigration];
        }
    }
    return self;
}

- (BOOL)isMigrationNeeded {
    return (BOOL) [CTPreferences getIntForKey:CLTAP_ENCRYPTION_MIGRATION_STATUS withResetValue:YES];
}

- (void)performMigration {
    NSMutableArray *failures = [NSMutableArray new];
    BOOL migratedGUIDSuccesfully = NO;
    BOOL migratedUserProfileDataSuccesfully = NO;
    BOOL migratedInAppDataSuccesfully = NO;
    
    if (_config.encryptionLevel == CleverTapEncryptionMedium) {
        migratedGUIDSuccesfully = [self migrateGUIDS];
        if (!migratedGUIDSuccesfully) [failures addObject:@"GUID migration failed"];
        
        migratedUserProfileDataSuccesfully = [self migrateUserProfileData];
        if (!migratedUserProfileDataSuccesfully) [failures addObject:@"User profile migration failed"];
    }
    
    migratedInAppDataSuccesfully = [self migrateInAppData];
    if (!migratedInAppDataSuccesfully) [failures addObject:@"In-app data migration failed"];
    
    if (migratedGUIDSuccesfully && migratedUserProfileDataSuccesfully && migratedInAppDataSuccesfully) {
        [CTPreferences putInt:0 forKey:CLTAP_ENCRYPTION_MIGRATION_STATUS];
        CleverTapLogDebug(_config.logLevel, @"%@: Migration completed successfully", self);
    } else {
        [CTPreferences putInt:1 forKey:CLTAP_ENCRYPTION_MIGRATION_STATUS];
        CleverTapLogDebug(_config.logLevel, @"%@: Migration failed: %@", self, [failures componentsJoinedByString:@", "]);
    }
}

#pragma mark - GUID Migration

- (BOOL)migrateGUIDS {
    NSString *cacheKey = [CTUtils getKeyWithSuffix:kCachedGUIDSKey accountID:_config.accountId];
    NSDictionary *cachedGUIDS = [CTPreferences getObjectForKey:cacheKey];
    if (!cachedGUIDS) return NO;
    
    NSMutableDictionary *newCache = [NSMutableDictionary new];
    [cachedGUIDS enumerateKeysAndObjectsUsingBlock:^(NSString* cachedKey, NSString* value, BOOL* stop) {
        NSArray *components = [cachedKey componentsSeparatedByString:@"_"];
        if (components.count != 2) return;
        
        NSString *key = components[0];
        NSString *identifier = components[1];
        
        if (identifier && ![_cryptManager isTextAESGCMEncrypted:identifier]) {
            NSString *decryptedString = [_cryptManager decryptString:identifier encryptionAlgorithm:AES];
            if (decryptedString) {
                NSString *migratedEncryptedString = [_cryptManager encryptString:decryptedString];
                newCache[[NSString stringWithFormat:@"%@_%@", key, migratedEncryptedString]] = value;
            }
        }
    }];
    
    [CTPreferences putObject:newCache forKey:cacheKey];
    return YES;
}

#pragma mark - In-app Migration

- (BOOL)migrateInAppData {
    return ([self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY] &&
            [self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_CS] &&
            [self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_SS]);
}

- (BOOL)migrateInAppsWithKeySuffix:(NSString *)keySuffix {
    NSString *key = [self storageKeyWithSuffix:keySuffix];
    NSString *encryptedString = [CTPreferences getObjectForKey:key];
    
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
    long lastEncryptionLevel = [CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:CT_DECRYPTION_KEY accountID:self.config.accountId] withResetValue:0];
    
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
